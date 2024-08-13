use anyhow::Result;
use serde::{Deserialize, Serialize};
use similar::{Change, ChangeTag, TextDiff};
use wasm_minimal_protocol::*;

initiate_protocol!();

#[derive(Serialize, Deserialize, Clone, PartialEq, Eq)]
enum LineTag {
    Insert,
    Delete,
    Equal,
    Spacer,
}

#[derive(Serialize, Deserialize, Clone, PartialEq, Eq)]
struct Line {
    tag: LineTag,
    old_index: Option<usize>,
    new_index: Option<usize>,
    content: String,
}

#[derive(Serialize, Deserialize)]
struct Code {
    to_show_lines: Vec<Line>,
    lines: Vec<Line>,
}

impl From<Change<&str>> for Line {
    fn from(change: Change<&str>) -> Line {
        Line {
            tag: match change.tag() {
                ChangeTag::Delete => LineTag::Delete,
                ChangeTag::Insert => LineTag::Insert,
                ChangeTag::Equal => LineTag::Equal,
            },
            old_index: change.old_index(),
            new_index: change.new_index(),
            content: change.to_string(),
        }
    }
}

#[derive(Serialize, Deserialize)]
struct Args {
    content_before: String,
    content_after: String,
    always_show_lines: Vec<usize>,
    context_lines_count: usize,
}

#[wasm_func]
pub fn parse_diff_code(args: &[u8]) -> Result<Vec<u8>> {
    let Args {
        content_before,
        content_after,
        always_show_lines,
        context_lines_count,
    } = serde_json::from_slice(args)?;

    let diff = TextDiff::from_lines(content_before.as_str(), content_after.as_str());

    let lines: Vec<Line> = diff.iter_all_changes().map(Line::from).collect();
    let to_show_lines = lines.iter().enumerate().filter(|(i, line)| {
        should_show_line(&lines, &always_show_lines, context_lines_count, line, *i)
    });
    let to_show_lines = to_show_lines
        .fold(
            (
                Vec::with_capacity(lines.capacity()),
                Vec::with_capacity(lines.capacity()),
            ),
            |mut acc: (Vec<usize>, Vec<Line>), (i, line)| {
                let last_i = acc.0.last();
                let last_line = acc.1.last();

                if let Some(last_i) = last_i {
                    if let Some(last_line) = last_line {
                        if last_i.abs_diff(i) > 1 && last_line.tag != LineTag::Spacer {
                            acc.0.push(i);
                            acc.1.push(Line {
                                tag: LineTag::Spacer,
                                old_index: None,
                                new_index: None,
                                content: "".to_owned(),
                            });
                        }
                    }
                }

                acc.0.push(i);
                acc.1.push(line.to_owned());
                acc
            },
        )
        .1;

    let result = Code {
        to_show_lines,
        lines,
    };

    Ok(serde_json::to_vec(&result)?)
}

fn should_show_line(
    lines: &[Line],
    always_show_lines: &[usize],
    context_lines_count: usize,
    line: &Line,
    index: usize,
) -> bool {
    if line.tag != LineTag::Equal || always_show_lines.contains(&line.old_index.unwrap()) {
        return true;
    }

    let context_range_start = index.saturating_sub(context_lines_count);
    let context_range_end = (index + context_lines_count).min(lines.len() - 1);

    lines[context_range_start..(context_range_end + 1)]
        .iter()
        .any(|line| line.tag != LineTag::Equal)
}

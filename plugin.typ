#let plugin = plugin("./target/wasm32-unknown-unknown/release/code_info.wasm");

#let to-string(content) = {
  if type(content) == "string" {
    content
  } else if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let parse-diff-code(
  content-before,
  content-after,
  always-show-lines: (),
  context-lines-count: 3,
) = json.decode(
  plugin.parse_diff_code(
    bytes(
      json.encode((
        content_before: to-string(content-before),
        content_after: to-string(content-after),
        always_show_lines: always-show-lines.map(v => v - 1),
        context_lines_count: context-lines-count,
      )),
    ),
  ),
)

#let default-code-info = (
  caption: none,
  label: none,
  show-line-numbers: false,
  start-line: 1,
  highlighted-lines: (),
  added-lines: (),
  deleted-lines: (),
  diff: false,
  always-show-lines: (),
)

#let code-info-state = state("code-info", default-code-info)

#let code-info(
  caption: default-code-info.caption,
  label: default-code-info.label,
  show-line-numbers: default-code-info.show-line-numbers,
  start-line: default-code-info.start-line,
  highlighted-lines: default-code-info.highlighted-lines,
  added-lines: default-code-info.added-lines,
  deleted-lines: default-code-info.deleted-lines,
  diff: default-code-info.diff,
  always-show-lines: default-code-info.always-show-lines,
) = {
  code-info-state.update((
    caption: caption,
    label: label,
    diff: diff,
    show-line-numbers: show-line-numbers,
    start-line: start-line,
    highlighted-lines: highlighted-lines,
    added-lines: added-lines,
    deleted-lines: deleted-lines,
    always-show-lines: always-show-lines,
  ))
}

#let default-diff-code = (
  before: none,
  after: none,
)

#let diff-code-state = state("diff-code", default-diff-code)

#let code-block(
  caption: none,
  label: none,
  supplement: none,
  mono-font: none,
  content,
) = [
  #h(2em)
  #figure(
    kind: raw,
    caption: if caption == none {
      if label == none {
        none
      } else {
        ""
      }
    } else {
      caption
    },
    supplement: supplement,
    numbering: if label == none {
      none
    } else {
      "1"
    },
    gap: 1em,
    {
      set par(justify: false)
      set text(size: 9pt)
      if mono-font != none {
        set text(font: mono-font)
      }
      set block(spacing: 1em, above: 1em, below: 1em)
      set line(length: 100%, stroke: 0.5pt)

      line()
      content
      line()
    },
  ) #if label != none {
    label(label)
  }
  #h(2em)
]

#let init-code-info(
  breakable: true,
  supplement: "Listing",
  body-font: "linux libertine",
  mono-font: "mono",
  body,
) = {
  show raw.where(block: true): it => locate(loc => {
    let cur-code-info = code-info-state.at(loc)
    let start-line = cur-code-info.start-line
    let show-line-numbers = cur-code-info.show-line-numbers
    let highlighted-lines = cur-code-info.highlighted-lines
    let added-lines = cur-code-info.added-lines
    let deleted-lines = cur-code-info.deleted-lines
    let is-diff = cur-code-info.diff
    let always-show-lines = cur-code-info.always-show-lines
    let typst-line = line

    let cur-diff-code = diff-code-state.at(loc)

    show figure: set block(breakable: breakable)
    show figure.caption: set text(font: body-font)
    set figure.caption(
      position: top,
      separator: if cur-code-info.caption == none {
        none
      } else {
        auto
      },
    )

    let code-block-content = grid(
      columns: if show-line-numbers {
        (auto, 1fr)
      } else {
        (1fr)
      },
      inset: 0.3em,
      align: left + top,
      stroke: none,
      ..it
        .lines
        .map(line => {
            let line-number = line.number + start-line - 1
            let show-highlighted = highlighted-lines.contains(line-number)
            let show-added = added-lines.contains(line-number)
            let show-deleted = deleted-lines.contains(line-number)
            let line-number-color = if show-added {
              rgb("#228b22")
            } else if show-deleted {
              rgb("b22222")
            } else {
              gray
            }
            let line-bg-color = if show-highlighted {
              rgb("#cfecfc")
            } else if show-added {
              rgb("#d6f2c7")
            } else if show-deleted {
              rgb("#ffd9d9")
            } else {
              rgb(0, 0, 0, 0)
            }

            let line-number-content = grid.cell(
              inset: (right: 1.2em),
              text(
                fill: line-number-color,
                weight: if show-added or show-deleted {
                  "bold"
                } else {
                  "regular"
                },
                str(line-number),
              ),
            )
            if show-line-numbers {
              (
                line-number-content,
                grid.cell(
                  fill: line-bg-color,
                  line,
                ),
              )
            } else {
              grid.cell(
                inset: (x: 1.2em),
                fill: line-bg-color,
                line,
              )
            }
          })
        .flatten()
    )

    if (is-diff) {
      if (cur-diff-code.before == none and cur-diff-code.after == none) {
        diff-code-state.update((
          before: it,
          after: none,
        ))
      } else {
        let code-content-before = cur-diff-code.before
        let code-content-after = it

        let diff-code = parse-diff-code(
          always-show-lines: always-show-lines,
          code-content-before,
          code-content-after,
        )

        let code-lines-before = code-content-before.lines
        let code-lines-after = code-content-after.lines

        let code-block-content = grid(
          columns: if show-line-numbers {
            (auto, auto, 1fr)
          } else {
            (auto, 1fr)
          },
          inset: (y: 0.3em),
          align: left + top,
          stroke: none,
          ..diff-code
            .to_show_lines
            .enumerate()
            .map(((index, line)) => {
                let show-highlighted = highlighted-lines.contains(index)
                let show-added = line.tag == "Insert"
                let show-deleted = line.tag == "Delete"
                let line-number-color = if show-added {
                  rgb("#228b22")
                } else if show-deleted {
                  rgb("b22222")
                } else {
                  gray
                }
                let line-bg-color = if show-highlighted {
                  rgb("#cfecfc")
                } else if show-added {
                  rgb("#d6f2c7")
                } else if show-deleted {
                  rgb("#ffd9d9")
                } else {
                  rgb(0, 0, 0, 0)
                }

                let line-number = if line.new_index != none {
                  line.new_index + 1
                } else if line.old_index != none {
                  line.old_index + 1
                } else {
                  none
                }
                let line-number-content = grid.cell(
                  fill: line-bg-color,
                  inset: (left: 0.3em, right: 1.2em),
                  text(
                    fill: line-number-color,
                    weight: if show-added or show-deleted {
                      "bold"
                    } else {
                      "regular"
                    },
                    if line-number == none {
                      ""
                    } else {
                      str(line-number)
                    },
                  ),
                )

                let line-content = if line.tag == "Spacer" {
                  text(fill: line-number-color, line.content)
                } else if line.new_index != none {
                  code-lines-after.at(line.new_index)
                } else if line.old_index != none {
                  code-lines-before.at(line.old_index)
                } else {
                  none
                }

                let line-tag-content = grid.cell(
                  fill: line-bg-color,
                  inset: (
                    left: if show-line-numbers {
                      0em
                    } else {
                      1.2em
                    },
                    right: 0.5em,
                  ),
                  text(
                    fill: line-number-color,
                    if line.tag == "Insert" {
                      "+"
                    } else if line.tag == "Delete" {
                      "-"
                    } else {
                      " "
                    },
                  ),
                )

                if line.tag == "Spacer" {
                  grid.cell(
                    fill: line-bg-color,
                    inset: (y: 1em),
                    colspan: if show-line-numbers {
                      3
                    } else {
                      2
                    },
                    {
                      let height = 9pt
                      let gap = 6pt
                      let stroke = (
                        paint: line-number-color,
                        thickness: 1pt,
                        cap: "round",
                      )
                      let wavy-line = pattern(size: (13pt, height))[
                        #place(
                          path(
                            stroke: stroke,
                            ((0pt, 1pt), (-25%, 0pt)),
                            ((50%, height - gap), (-25%, 0pt)),
                            ((100%, 1pt), (-25%, 0pt)),
                          ),
                        )
                        #place(
                          path(
                            stroke: stroke,
                            ((0pt, gap), (-25%, 0pt)),
                            ((50%, height - 1pt), (-25%, 0pt)),
                            ((100%, gap), (-25%, 0pt)),
                          ),
                        )
                      ]
                      rect(fill: wavy-line, width: 100%, height: height)
                    },
                  )
                } else if show-line-numbers {
                  (
                    line-number-content,
                    line-tag-content,
                    grid.cell(
                      inset: (right: 0.3em),
                      fill: line-bg-color,
                      line-content,
                    ),
                  )
                } else {
                  (
                    line-tag-content,
                    grid.cell(
                      inset: (right: 1.2em),
                      fill: line-bg-color,
                      line-content,
                    ),
                  )
                }
              })
            .flatten()
        )

        code-info-state.update(default-code-info)
        diff-code-state.update(default-diff-code)

        code-block(
          caption: cur-code-info.caption,
          label: cur-code-info.label,
          supplement: supplement,
          mono-font: mono-font,
          code-block-content,
        )
      }
    } else {
      code-info-state.update(default-code-info)

      code-block(
        caption: cur-code-info.caption,
        label: cur-code-info.label,
        supplement: supplement,
        mono-font: mono-font,
        code-block-content,
      )
    }
  })

  body
}

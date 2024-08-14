import { copy } from "jsr:@std/fs@1.0.1"

if (import.meta.main) {
  await Deno.mkdir("dist", { recursive: true })

  await copy(
    "target/wasm32-unknown-unknown/release/code_info.wasm",
    "dist/plugin.wasm",
    { overwrite: true },
  )
  await copy("plugin.typ", "dist/plugin.typ", { overwrite: true })
  await copy("typst.toml", "dist/typst.toml", { overwrite: true })
  await copy("LICENSE", "dist/LICENSE", { overwrite: true })
  await copy("README.md", "dist/README.md", { overwrite: true })
  await copy(".github/fixtures", "dist/.github/fixtures", { overwrite: true })

  await Deno.writeTextFile(
    "dist/plugin.typ",
    (await Deno.readTextFile("dist/plugin.typ")).replace(
      /(#let\s+PLUGIN_WASM_PATH\s+=\s+)".*?"/,
      '$1"./plugin.wasm"',
    ),
  )
}

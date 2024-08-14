/**
 * Generate SVG from Typst
 *
 * @example
 * ```sh
 * deno run -A .github/scripts/typst2svg.ts .github/fixtures/diff.typ .github/fixtures/line-numbers.typ
 * ```
 */

/// <reference lib="dom" />
/// <reference lib="dom.iterable" />

import $ from "jsr:@david/dax@0.41.0"
import path from "node:path"
import puppeteer, { type Browser } from "npm:puppeteer@22.0.0"

export const typst2svg = async (...typstPaths: string[]) => {
  const browser = await puppeteer.launch({ headless: "shell" })

  for (const typstPath of typstPaths) {
    const svgPath = typstPath.replace(/\.typ$/, ".svg")
    const dirname = import.meta.dirname
    if (!dirname) throw new Error("Failed to get the dirname")
    const rootDir = path.resolve(dirname, "../..")

    // Generate SVG
    await $`typst compile ${typstPath} --root ${rootDir} --format svg`
    console.log(`Generated SVG at ${svgPath}`)

    // Transform SVG
    try {
      await transformSvg(browser, svgPath)
      console.log(`Transformed SVG at ${svgPath}`)
    } catch (e) {
      console.error(e)
      break
    }
  }

  console.log("Closing browser...")
  browser.close()
}

const transformSvg = async (browser: Browser, svgPath: string) => {
  const page = await browser.newPage()

  const svgUrl = `file://${path.resolve(Deno.cwd(), svgPath)}`
  await page.goto(svgUrl)

  const svg = await page.$("svg")
  if (!svg) {
    throw new Error("Failed to find the SVG element")
  }

  const [width, height] = await page.evaluate((svg) => {
    const g = svg.querySelector("g")
    const bbox = g?.getBBox()
    return [bbox?.width, bbox?.height]
  }, svg)
  if (!width || !height) {
    throw new Error("Failed to get width and height of the SVG")
  }

  const margin = 20
  const outputSvg = await page.evaluate(
    (svg, width, height, margin) => {
      svg.setAttribute(
        "viewBox",
        `0 0 ${width + margin * 2} ${height + margin * 2}`,
      )
      svg.removeAttribute("width")
      svg.removeAttribute("height")
      svg.setAttribute("style", "background-color: white;")

      const gs = svg.querySelectorAll<SVGGElement>("svg > g > g")
      if (!gs) return svg.outerHTML
      let curHeight = margin
      for (const g of gs) {
        const bbox = g.getBBox()

        g.setAttribute(
          "transform",
          `translate(${margin} ${curHeight})`,
        )

        curHeight += bbox.height + margin
      }

      return svg.outerHTML
    },
    svg,
    width,
    height,
    margin,
  )

  await Deno.writeTextFile(svgPath, outputSvg)
}

if (import.meta.main) {
  if (Deno.args.length === 0) {
    console.error(
      "Usage: deno run -A .github/scripts/typst2svg.ts <typst-path>",
    )
    Deno.exit(1)
  }

  await typst2svg(...Deno.args)
}

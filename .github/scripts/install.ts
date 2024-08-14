import * as path from "jsr:@std/path@1.0.2"
import * as TOML from "jsr:@std/toml@1.0.0"
import { walk } from "jsr:@std/fs@1.0.1"

const NAMESPACE = "local"

/**
 * Get the data directory for the current platform.
 * @see https://github.com/typst/packages#local-packages
 */
const getDataDir = () => {
  switch (Deno.build.os) {
    case "darwin":
      return path.join(Deno.env.get("HOME")!, "Library", "Application Support")
    case "windows":
      return path.join(Deno.env.get("APPDATA")!)
    default:
      return path.join(Deno.env.get("HOME")!, ".local", "share")
  }
}

/**
 * The package metadata format.
 * @see https://github.com/typst/packages#package-format
 */
type Package = {
  name: string
  version: `${string}.${string}.${string}`
  entrypoint: string

  authors: string[]
  license: string
  description: string

  homepage?: string
  repository?: string
  keywords?: string[]
  categories?: string[]
  disciplines?: string[]
  compiler?: `${string}.${string}.${string}`
  exclude?: string[]
}

/**
 * Get the package metadata from typst.toml.
 */
const getPackageMeta = (packageTomlPath: string) => {
  const packageToml = Deno.readTextFileSync(packageTomlPath)
  const packageMeta = TOML.parse(packageToml).package as Package
  return packageMeta
}

if (import.meta.main) {
  const dirname = import.meta.dirname
  if (!dirname) throw new Error("dirname is not defined")
  const rootDir = path.resolve(dirname, "../..")
  const distDir = path.join(rootDir, "dist")

  // Get the data directory
  const dataDir = getDataDir()

  // Read the package metadata from typst.toml
  const packageMeta = getPackageMeta(path.resolve(distDir, "typst.toml"))

  // Create the package directory
  const packageDir = path.join(
    dataDir,
    "typst",
    "packages",
    NAMESPACE,
    packageMeta.name,
    packageMeta.version,
  )
  await Deno.mkdir(packageDir, { recursive: true })

  // Copy the package files
  const packageFiles = walk(distDir, { includeDirs: false })
  const excludeFiles = packageMeta.exclude?.map((file) =>
    Deno.realPathSync(file)
  ) ?? []
  for await (const packageFile of packageFiles) {
    const fromPath = packageFile.path
    const toPath = path.resolve(packageDir, path.relative(distDir, packageFile.path))
    if (excludeFiles.includes(fromPath)) continue
    await Deno.mkdir(path.dirname(toPath), { recursive: true })
    await Deno.copyFile(fromPath, toPath)
  }

  // Log the success message
  console.log(
    `Installed ${packageMeta.name} v${packageMeta.version} successfully!`,
  )
  console.log(`The package is stored in \`${packageDir}\``)
  console.log("")
  console.log(
    `You can import the package with \`#import "@local/${packageMeta.name}:${packageMeta.version}": *\``,
  )
}

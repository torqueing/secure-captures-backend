// Bundles each Lambda entry point with esbuild and zips it into dist/<name>.zip,
// which Terraform deploys.
import { build } from 'esbuild';
import { execFileSync } from 'node:child_process';
import { mkdirSync, rmSync, utimesSync } from 'node:fs';

const functions = {
  api: 'src/api/handler.ts',
  'post-confirmation': 'src/triggers/postConfirmation.ts',
};

rmSync('dist', { recursive: true, force: true });

for (const [name, entry] of Object.entries(functions)) {
  const outdir = `dist/${name}`;
  mkdirSync(outdir, { recursive: true });
  await build({
    entryPoints: [entry],
    outfile: `${outdir}/index.mjs`,
    bundle: true,
    platform: 'node',
    target: 'node22',
    format: 'esm',
    minify: true,
    sourcemap: 'inline',
    // Some AWS SDK dependencies still call require(); give ESM bundles a working one.
    banner: { js: "import { createRequire } from 'node:module'; const require = createRequire(import.meta.url);" },
    legalComments: 'none',
  });
  // A fixed timestamp and -X (no uid/gid) make identical code give an identical zip hash,
  // so Terraform only redeploys a function when its code changed.
  utimesSync(`${outdir}/index.mjs`, 315532800, 315532800);
  execFileSync('zip', ['-q', '-X', '-j', `dist/${name}.zip`, `${outdir}/index.mjs`]);
  console.log(`built dist/${name}.zip`);
}

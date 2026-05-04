---
name: dst-image-processing
description: Process image assets for this Don't Starve Together mod. Use when the user asks to handle pictures, PNG/JPG/BMP assets, remove white or solid backgrounds, make transparent-background images, batch cut/crop images, generate transparent PNGs, or export processed images from `_素材` to `_素材/out`.
---

# DST Image Processing

Use this skill for project image cleanup and batch transparent-background output.

## Core Rules

- Keep source images in `_素材` unchanged.
- Write processed images to `_素材/out`.
- Do not move source files into `exported_done`, `images_done`, `_素材_done`, or similar archive folders unless the user explicitly asks.
- Do not run DST compile tools or generate `anim/*.zip`, `*.tex`, or `*.xml` for this workflow.
- Preserve PNG output unless the user requests another format.
- If the visual result is poor, improve the processing script or parameters and rerun it; do not leave a weak one-off output as final.

## Default Workflow

1. Inspect input images:

```powershell
Get-ChildItem -LiteralPath '.\_素材' -File | Select-Object Name,Length,Extension
```

2. Run the batch cutter:

```powershell
node .\gen\imageCutter\imageCutter.js
```

3. Confirm output files are in `_素材/out`:

```powershell
Get-ChildItem -LiteralPath '.\_素材\out' -File | Select-Object Name,Length,Extension
```

4. Visually verify at least one light/checkerboard and one darker preview when background removal is involved. Use `view_image` on the output and, when transparency is hard to see, create a temporary checkerboard composite for inspection.

5. Report the generated file paths and any important parameter changes.

## Batch Cutter Behavior

`gen/imageCutter/imageCutter.js` is the canonical script for this workflow. It:

- reads images from `_素材`;
- removes the background by flood-filling from image edges, following the `gen/imageCutter/index.html` bucket logic;
- applies a transparent-edge pass to reduce pale anti-aliased fringes;
- fades the newly transparent edge;
- trims transparent empty space;
- writes PNG files into `_素材/out`.

Default command:

```powershell
node .\gen\imageCutter\imageCutter.js
```

Useful options:

```powershell
node .\gen\imageCutter\imageCutter.js --tolerance 35
node .\gen\imageCutter\imageCutter.js --fade 1
node .\gen\imageCutter\imageCutter.js --transparent-edge 4
node .\gen\imageCutter\imageCutter.js --no-crop
node .\gen\imageCutter\imageCutter.js --input '.\_素材' --output '.\_素材\out'
```

Parameter guidance:

- Increase `--tolerance` when a near-white or flat-color background remains connected to the edges.
- Decrease `--tolerance` if pale highlights inside the item are being removed.
- Increase `--transparent-edge` when dark outlines still show white or gray fringe.
- Decrease `--transparent-edge` if genuine gray detail near the outer edge becomes too thin.
- Use `--no-crop` only when the user needs the original canvas size preserved.

## Quality Checks

After processing:

- Confirm alpha exists and output dimensions are expected.
- Check that internal white highlights, item holes, and thin black line art were not incorrectly erased.
- Check that the edge has no obvious white halo on a medium or dark checkerboard.
- For DST inventory or animation source images, make sure cropping did not remove intentional cast shadows unless the user requested tight item-only cutouts.

When scripting temporary checks on Windows, avoid inline Node snippets that contain literal Chinese path segments if the shell corrupts encoding. Prefer `path.join(process.cwd(), '_' + '\u7d20\u6750', 'out')` inside Node snippets, or use the checked-in `imageCutter.js` directly.

## When Results Need Tuning

If the default output is not acceptable:

1. Compare the original and output on a checkerboard background.
2. Identify whether the failure is background left behind, subject erased, white fringe, or over-cropping.
3. Rerun with adjusted `--tolerance`, `--transparent-edge`, `--fade`, or `--no-crop`.
4. If a recurring issue cannot be fixed with parameters, patch `gen/imageCutter/imageCutter.js` and rerun it.
5. Re-verify visually before final response.

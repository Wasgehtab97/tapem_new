# Tap'em Website

Marketing site built with Next.js App Router and exported as static HTML (`output: "export"`).

## Local development

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
```

The static output is generated in `out/`.

## Deploy to Cloudflare Pages

Use these settings in Cloudflare Pages:

- Framework preset: `Next.js (Static HTML Export)`
- Build command: `npm run build`
- Build output directory: `out`
- Root directory: `tapem/website/tapem-site` (if repo root is above this folder)

## Domain connection (STRATO -> Cloudflare Pages)

1. Add domain in Cloudflare (`tapem.de`).
2. Change nameservers in STRATO to the two nameservers shown by Cloudflare.
3. In Cloudflare Pages, add `tapem.de` and `www.tapem.de` as custom domains.
4. Configure redirect `www.tapem.de -> tapem.de`.
5. Wait for DNS propagation and verify HTTPS.

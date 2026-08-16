# BarKeep website

The static landing page is deployed to Cloudflare Pages. Its download link is
fulfilled by the packaged app in `dist/`, which is copied into a temporary
deployment directory by `script/deploy_website.sh`.

```sh
./script/build_and_run.sh --package
./script/deploy_website.sh
```

The deploy script does not modify `website/` or commit the generated app zip.

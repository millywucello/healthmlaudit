# Activate GitHub Actions

The workflow is ready in [R-CMD-check.yaml](R-CMD-check.yaml), but GitHub rejected
its upload to `.github/workflows/` because the saved personal access token lacks
the `workflow` permission. No account permissions were changed, and no CI pass
is claimed.

A repository owner can activate it in the GitHub web interface:

1. Sign into GitHub and open `millywucello/healthmlaudit`.
2. Choose **Add file > Create new file**.
3. Name the file `.github/workflows/R-CMD-check.yaml`.
4. Copy the contents of the workflow in this folder into the editor and commit.
5. Open **Actions** and check that **R-CMD-check** completes successfully.

Alternatively, after configuring an existing approved GitHub credential that
can write workflow files, run these commands from the repository root:

```sh
mkdir -p .github/workflows
cp docs/ci/R-CMD-check.yaml .github/workflows/R-CMD-check.yaml
git add .github/workflows/R-CMD-check.yaml
git commit -m "Activate R package checks"
git push
```

The workflow runs on Ubuntu with the current R release, installs the declared
package dependencies and rcmdcheck, builds the vignette, and fails on package
warnings or errors. Repository permission is limited to `contents: read`.
The local R CMD check and tests already pass; their evidence is in
`docs/validation/`.

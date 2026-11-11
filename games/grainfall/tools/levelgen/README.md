Level generator scripts used to author the shipped level JSON (one per authoring batch).
They write into a staging folder; copy results into `Sources/GrainfallCore/Resources/levels/`
and run `tools/set_pars.py`. The JSON files are the source of truth — these are kept for
reproducibility and as examples of programmatic level design.

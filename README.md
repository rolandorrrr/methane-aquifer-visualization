# Like Mixing Oil with Water: Assessing Methane Contamination from Orphaned Oil Wells in U.S. Aquifers

**Author:** Rolando H. Rabines (Tufts University, B.S. Human Factors Engineering)  
**Interactive Quarto / R Report:** [View Live HTML Report](https://rolandorrrr.github.io/methane-aquifer-visualization/) · [rolandorabines.com/lab](https://rolandorabines.com/lab/)  
**Research Poster (48×36 PDF):** [`48x36_Rabines_Rolando_Project_Poster.pdf`](./48x36_Rabines_Rolando_Project_Poster.pdf)

---

## Overview
An environmental data visualization and spatial statistical analysis investigating the relationship between dissolved methane concentrations in U.S. principal aquifers and their proximity to unplugged orphaned oil and gas wells, combining datasets from the **U.S. Geological Survey (USGS)** and **Environmental Protection Agency (EPA)**.

### Key Methods & Stack
- **Languages & Packages:** R (`tidyverse`, `ggplot2`, `sf`, `geosphere`, `maps`, `viridis`, `patchwork`), Quarto (`.qmd` → Bootstrap 5 HTML5).
- **Spatial Linking:** Haversine nearest-neighbor distance computation linking U.S. groundwater monitoring wells with documented orphaned oil and gas wells across **2.5 km, 5 km, 10 km, and 25 km** proximity thresholds.
- **Statistical Testing:** Non-parametric **Mann-Whitney U (Wilcoxon rank-sum)** and **Spearman rank correlation** analyses comparing log-scale methane distributions (`mg/L`) near orphaned wells against random baseline aquifer samples.

## Repository Contents
- `index.html` / `Rabines_Rolando_FinalProjectV47.html` — Compiled interactive Quarto HTML report with code blocks, statistical outputs, and `ggplot2` visualizations.
- `Rabines_Rolando_FinalProjectV47_files/` — Rendered figure assets (`figure-html/*.png`) and Quarto/Bootstrap libraries.
- `Rabines_Rolando_FinalProject.qmd` — Quarto source notebook.
- `analysis.R` — Standalone R spatial & statistical script.
- `48x36_Rabines_Rolando_Project_Poster.pdf` — Full 48×36 academic research poster.

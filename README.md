# Analysis Code: Extreme Rainfall and Urban Consumption in Chinese Business Districts

**Corresponding Manuscript:** *Extreme rainfall disrupts urban consumption and exposes uneven climate adaptation*

**Author:** Ye Shu (2025)

------

## 📋 Description

This repository contains the Stata analysis code for the paper "Extreme rainfall disrupts urban consumption and exposes uneven climate adaptation".

Using a dataset of 32 million high-frequency transaction records from 4,028 commercial districts across 40 Chinese cities (2019–2022), this study estimates the causal, nonlinear, and heterogeneous impacts of daily rainfall on offline urban consumption. The code implements high-dimensional fixed-effects models, distributed-lag models, and heterogeneity analyses to assess urban climate vulnerability.

------

## 📂 Repository Structure

- **`AnalysisCode_uploadVersion.txt`**: The master Stata `.do` file containing all empirical analyses, from data cleaning to robustness checks.

------

## 🛠️ Prerequisites

To run this code successfully, ensure you have the following environment:

- **Stata**: Version 16 or higher is recommended.

- User-written packages

  : The code relies on 

  ```
  reghdfe
  ```

   and 

  ```
  estout
  ```

  . Install them before running:

  ```stata
  ssc install reghdfessc install estout
  ```



------

## 📊 Analysis Workflow

The Stata script is organized into the following sections corresponding to the paper's methodology:

1. **Data Preparation**: Loads data, encodes string identifiers (Business District, City), and sets the panel structure (`xtset`).

2. Main Nonlinear Analysis

   :

   - Defines rainfall bins (10mm intervals).
   - Estimates consumption response using `reghdfe` with high-dimensional fixed effects.

3. Distributed-Lag Model

   :

   - Uses official rainfall grades (Light, Moderate, Heavy, etc.).
   - Estimates dynamic effects over 0–30 days post-rainfall.

4. Heterogeneity Analysis

   :

   - Subgroup regressions based on:
     - Historical rainfall exposure.
     - Population age structure (Elderly share).
     - Transport accessibility (Road density).
     - Impervious surface coverage.

5. Vulnerability Mapping

   :

   - Estimates interaction models to compute marginal loss per mm of rainfall.
   - Aggregates district-level vulnerability to the city level.

6. Robustness Checks

   :

   - Tests with restricted samples.
   - Compares transaction amounts vs. counts.
   - Excludes specific control variables (e.g., air pollution).

------

## 📜 Citation

If you use this code or find the associated paper helpful, please cite:

> Ye Shu et al. "Extreme rainfall disrupts urban consumption and exposes uneven climate adaptation." [Journal Name], [Year].

------

## 📧 Contact

For questions regarding the code or data analysis, please contact the corresponding author.

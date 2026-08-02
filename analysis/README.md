# AetherGain Weekly Analysis

Python companion for Criterion 8 — generates weekly PDF/CSV reports from the CSV
exported via the app's **Progress → Export CSV** button.

## Setup

```bash
pip install pandas matplotlib
```

## Usage

```bash
python3 generate_report.py aethergain_weekly.csv --out report.pdf --summary summary.csv
```

Outputs:
- `summary.csv` — one-row weekly totals & averages.
- `report.pdf`  — cover page + XP, workouts, and macros trend charts.

## Input schema

CSV exported by the app has these 11 columns:

```
date,day,xp,workouts,calories,protein_g,carbs_g,fat_g,water_ml,sleep_hours,habit_done
```

Each row is one calendar day of the last 7.

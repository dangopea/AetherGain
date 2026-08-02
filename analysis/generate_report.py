#!/usr/bin/env python3
"""
AetherGain weekly analysis (Criterion 8).

Reads a CSV exported from the app (Progress tab -> Export CSV) and produces:
  1. A CSV summary of weekly totals and averages.
  2. A PDF report with weekly trend charts (XP, workouts, macros, water, sleep).

Usage:
    python3 generate_report.py aethergain_weekly.csv --out report.pdf

CSV schema (11 columns):
    date,day,xp,workouts,calories,protein_g,carbs_g,fat_g,water_ml,sleep_hours,habit_done

Dependencies:
    pip install pandas matplotlib
"""

import argparse
import os
import sys
from datetime import datetime

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


PALETTE = {
    "coral":    "#FF8C7A",
    "lavender": "#B7AEFA",
    "mint":     "#8CDAB5",
    "sky":      "#8CCCF9",
    "peach":    "#FFC6A5",
    "sun":      "#FFD966",
}


def load(csv_path: str) -> pd.DataFrame:
    df = pd.read_csv(csv_path)
    df["date"] = pd.to_datetime(df["date"])
    df = df.sort_values("date").reset_index(drop=True)
    return df


def summarise(df: pd.DataFrame) -> dict:
    logged_meals = df[df["calories"] > 0]
    logged_sleep = df[df["sleep_hours"] > 0]
    return {
        "range_start": df["date"].min().strftime("%Y-%m-%d"),
        "range_end":   df["date"].max().strftime("%Y-%m-%d"),
        "total_xp":       int(df["xp"].sum()),
        "total_workouts": int(df["workouts"].sum()),
        "avg_calories":   round(logged_meals["calories"].mean(), 1) if not logged_meals.empty else 0.0,
        "avg_protein":    round(logged_meals["protein_g"].mean(), 1) if not logged_meals.empty else 0.0,
        "avg_carbs":      round(logged_meals["carbs_g"].mean(), 1) if not logged_meals.empty else 0.0,
        "avg_fat":        round(logged_meals["fat_g"].mean(), 1) if not logged_meals.empty else 0.0,
        "avg_water_ml":   round(df["water_ml"].mean(), 0),
        "avg_sleep":      round(logged_sleep["sleep_hours"].mean(), 1) if not logged_sleep.empty else 0.0,
        "habit_hit_days": int(df["habit_done"].sum()),
    }


def write_summary_csv(summary: dict, out_path: str) -> None:
    pd.DataFrame([summary]).to_csv(out_path, index=False)


def build_pdf(df: pd.DataFrame, summary: dict, out_path: str) -> None:
    with PdfPages(out_path) as pdf:
        # --- Cover / summary page ---
        fig = plt.figure(figsize=(8.5, 11))
        ax = fig.add_subplot(111)
        ax.axis("off")
        title = f"AetherGain Weekly Report\n{summary['range_start']} → {summary['range_end']}"
        ax.text(0.5, 0.92, title, ha="center", va="top", fontsize=20, fontweight="bold")

        stats_lines = [
            f"Total XP earned:         {summary['total_xp']}",
            f"Workouts completed:      {summary['total_workouts']}",
            f"Days habits completed:   {summary['habit_hit_days']}",
            "",
            f"Avg calories / logged day:  {summary['avg_calories']:.0f} kcal",
            f"Avg protein:                {summary['avg_protein']:.0f} g",
            f"Avg carbs:                  {summary['avg_carbs']:.0f} g",
            f"Avg fat:                    {summary['avg_fat']:.0f} g",
            "",
            f"Avg water (today snapshot): {summary['avg_water_ml']:.0f} ml",
            f"Avg sleep / logged day:     {summary['avg_sleep']:.1f} h",
        ]
        ax.text(0.08, 0.78, "\n".join(stats_lines), va="top", fontsize=13,
                family="monospace")
        ax.text(0.5, 0.04,
                f"Generated {datetime.now().strftime('%Y-%m-%d %H:%M')}",
                ha="center", va="bottom", fontsize=9, color="gray")
        pdf.savefig(fig)
        plt.close(fig)

        # --- XP + workouts page ---
        fig, axes = plt.subplots(2, 1, figsize=(8.5, 11))
        axes[0].bar(df["day"], df["xp"], color=PALETTE["lavender"])
        axes[0].set_title("Daily XP")
        axes[0].set_ylabel("XP")
        axes[1].bar(df["day"], df["workouts"], color=PALETTE["mint"])
        axes[1].set_title("Workouts per day")
        axes[1].set_ylabel("Sessions")
        for ax in axes:
            ax.spines["top"].set_visible(False)
            ax.spines["right"].set_visible(False)
        fig.tight_layout()
        pdf.savefig(fig)
        plt.close(fig)

        # --- Macros page ---
        fig, ax = plt.subplots(figsize=(8.5, 6))
        ax.plot(df["day"], df["protein_g"], marker="o", color=PALETTE["lavender"], label="Protein (g)")
        ax.plot(df["day"], df["carbs_g"],   marker="o", color=PALETTE["peach"],    label="Carbs (g)")
        ax.plot(df["day"], df["fat_g"],     marker="o", color=PALETTE["sky"],      label="Fat (g)")
        ax.set_title("Macros trend")
        ax.set_ylabel("Grams")
        ax.legend()
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)
        fig.tight_layout()
        pdf.savefig(fig)
        plt.close(fig)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="AetherGain weekly analysis report")
    parser.add_argument("csv", help="Path to CSV exported from the app")
    parser.add_argument("--out", default="report.pdf", help="Output PDF path")
    parser.add_argument("--summary", default="summary.csv",
                        help="Output CSV summary path")
    args = parser.parse_args(argv)

    if not os.path.isfile(args.csv):
        print(f"Input CSV not found: {args.csv}", file=sys.stderr)
        return 1

    df = load(args.csv)
    if df.empty:
        print("No rows in input CSV.", file=sys.stderr)
        return 1

    summary = summarise(df)
    write_summary_csv(summary, args.summary)
    build_pdf(df, summary, args.out)
    print(f"Summary CSV: {args.summary}")
    print(f"PDF report:  {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Summarize corrected BancoFisica exams and append item statistics."""
from __future__ import annotations
import argparse, csv, statistics
from pathlib import Path

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("responses", type=Path, help="CSV with public_code and Q1..Q10")
    ap.add_argument("manifest", type=Path, help="gabarito_mestre.csv")
    args=ap.parse_args()
    with args.manifest.open(encoding="utf-8") as f:
        keys={r["public_code"]:[r[f"Q{i}"] for i in range(1,11)] for r in csv.DictReader(f)}
    rows=list(csv.DictReader(args.responses.open(encoding="utf-8")))
    scores=[]; item_ok=[0]*10; item_n=[0]*10
    for r in rows:
        key=keys[r["public_code"]]
        score=0
        for i,k in enumerate(key,1):
            a=(r.get(f"Q{i}") or "").strip().upper()
            if a:
                item_n[i-1]+=1
                if a==k:
                    item_ok[i-1]+=1; score+=1
        scores.append(score)
    print(f"N={len(scores)}")
    print(f"mean={statistics.mean(scores):.2f} median={statistics.median(scores):.2f} min={min(scores)} max={max(scores)}")
    for i,(ok,n) in enumerate(zip(item_ok,item_n),1):
        rate=ok/n if n else float("nan")
        print(f"Q{i}: {ok}/{n} = {rate:.3f}")
if __name__=="__main__":
    main()

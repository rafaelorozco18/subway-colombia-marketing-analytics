# Subway Colombia — Competitive Marketing Analytics & Media Mix Modeling

> **Academic Project · Universidad Externado de Colombia · Marketing Analytics — Planeación de Medios, 2026**  
> Juan Sarmiento · Rafael Orozco  
> Period analyzed: January 2025 – March 2026

---

## Overview

A two-phase marketing analytics engagement diagnosing Subway Colombia's advertising position in a fast-food category dominated by global giants. Phase 1 is a **descriptive competitive diagnostic** (Share of Voice, message strategy, media mix) across 8 brands. Phase 2 is an **econometric Media Mix Model (MMM)** built with Meta's open-source **Robyn** framework, using Google Trends as a sales proxy to quantify each channel's actual marginal return.

**Core finding:** Subway has the right brand narrative (Subway Series, 52.5% of message share) but is delivering it through the wrong channel mix — oversaturated in traditional offline media while almost entirely absent from digital, where the model shows the highest marginal ROI.

---

## Data

| Source | Records | Period |
|---|---|---|
| Traditional ad investment (InfoAnálisis) | 68,492 insertions · 8 brands · 8 traditional media | Jan 2025 – Mar 2026 |
| Digital ad investment (Integra-metrics) | 482 insertions · 6 brands · 45 digital media | Q1 2026 |
| Google Trends ("Subway Colombia") | 65 weekly observations | Dec 2024 – Mar 2026 |

---

## Phase 1 — Competitive Diagnostic (Share of Voice)

### Key Findings
- **Subway is #4 in traditional SOV (12.6%)** but **penultimate in digital SOV (0.9%)** — the central paradox of the analysis
- **Investment fell -66% YoY in Q1 2026**, while direct rival **Sandwich Qbano grew +9%** — the competitive gap closed from 11x to 1.08x in twelve months
- **52.5% of Subway's message is pure innovation** (Subway Series campaign) — second highest in the category after Burger King — but **5.7%** of pieces mix innovation messaging with promotional CTAs, creating brand/price ambiguity
- **Health/freshness positioning is at 0.0%** of message share — Subway's one structurally defensible attribute against fried/pre-cooked competitors, left completely unused despite a 20% "unhealthy food" tax (Ley 2277) that disproportionately penalizes competitors
- Only **4.5% of Q1 2026 budget is digital**, vs. 57.2% (McDonald's) and 28.2% (Sandwich Qbano)

### Methodology
Heuristic keyword classification of ad copy into 5 mutually exclusive message axes (Pure Innovation / Innovation + Promotional CTA / Promo-Price / Health-Freshness / Generic), cross-validated against brand-level investment pivots.

---

## Phase 2 — Media Mix Model (Robyn)

### Why Robyn + Google Trends
Since weekly sales data isn't public, the weekly Google Trends search index for "Subway Colombia" was used as a demand proxy — an approach supported by academic literature (Choi & Varian, 2012) for high-frequency, low-consideration purchase categories like fast food.

### Model Configuration
```
Tool:          Robyn 3.11.1 (R) — Meta Open Source
Optimization:  Nevergrad evolutionary search, 10,400 candidate models
Pareto front:  187 models
Selection criteria: NRMSE < 0.20 · DECOMP.RSSD < 0.10 · Adj. R² > 0.80
```

### Selected Model Performance
| Metric | Value |
|---|---|
| Adjusted R² | **0.834** |
| NRMSE | 0.172 |
| DECOMP.RSSD | 0.089 |

### Response Decomposition
| Component | Contribution |
|---|---|
| Organic baseline (non-paid) | **52.3%** |
| TV Nacional | 17.8% (highest paid channel, but **71% saturated**) |
| Other traditional media | remainder |
| Facebook Ads | highest ROI: **4.82** index points / million COP |
| YouTube | 3.71 index points / million COP |

### Saturation & Carryover (Adstock)
- **TV Nacional & Publicidad Exterior** are operating beyond their inflection point — diminishing returns on further spend
- **Digital channels (Facebook, YouTube)** are deep in the underinvested zone of their response curve — every additional peso generates 3–5x the return of TV Nacional
- TV Nacional's adstock decays in ~4 weeks — explains why pulling spend for 6–8 weeks effectively resets brand activation to zero

### Budget Optimizer Result
Reallocating the **same total budget** — shifting digital share from 4.5% to 27.9% and reducing Prensa to near-zero — is projected to increase the average weekly Google Trends index by **+23.4%**.

---

## Strategic Recommendations

1. **Reallocate 25–30%** of budget toward Facebook Ads and YouTube — channels operating in the high-return zone of their saturation curve
2. **Invest continuously, not in waves** — adstock decay (2–5 weeks depending on channel) means pulling spend resets brand activation
3. **Reduce Prensa to residual levels** — lowest ROI channel (0.39 index points/million COP) with negligible contribution
4. **Strengthen TV Suscripción** — best offline ROI/saturation/carryover balance; ideal for 30-second narrative formats that Subway Series needs
5. **Activate the Health/Freshness axis** (currently 0.0%) and **separate brand messaging from promotional CTAs** — informed by the SOV diagnostic, reinforced by the macroeconomic context (20% ultra-processed food tax)

---

## Tech Stack

`R` · `Robyn (Meta)` · `Nevergrad` · `Google Trends API` · `ggplot2` · `Excel/InfoAnálisis pivots`

---

## Project Structure

```
subway-colombia-marketing-analytics/
├── README.md
├── data/
│   └── (BASE_COMPETENCIA_SUBWAY.xlsx, BASE_DIGITAL_SUBWAY_COMPETENCIA.xlsx — not public)
├── notebooks/
│   └── robyn_mmm_subway.R
├── docs/
│   ├── Subway_Estrategia_Basada_en_Datos.pdf       # Executive slide deck
│   ├── Informe_Subway_Analisis.docx                 # Full SOV diagnostic report
│   ├── Informe_Robyn_Subway_SarmientoOrozco.docx   # Full Robyn MMM technical report
│   ├── Anexo_Subway_Visualizaciones.docx            # 21 supporting visualizations
│   └── Anexo_Trends_Subway.docx                     # Google Trends supporting analysis
└── requirements.R
```

---

## Limitations

- 65 weeks of data is below Robyn's recommended minimum (104 weeks) — wider credibility intervals on channel parameters, especially Facebook Ads (14 weeks) and YouTube (11 weeks) of investment history
- Google Trends measures search interest, not verified sales or foot traffic — may overweight digital channels that generate direct search behavior
- Competitor investment was not included as a control variable

---

*Universidad Externado de Colombia · Facultad de Administración de Empresas · Marketing Analytics — Planeación de Medios · 2026*

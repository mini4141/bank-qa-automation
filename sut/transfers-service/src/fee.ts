const FEE_BASIS_POINTS = 150; // 1.5%

/** Fee in minor units. SUT_BUG_ROUNDING=1 seeds a defect: fees are rounded up instead of to nearest. */
export function computeFee(amountMinor: number, bugRounding = process.env.SUT_BUG_ROUNDING === "1"): number {
  const exact = (amountMinor * FEE_BASIS_POINTS) / 10000;
  return bugRounding ? Math.ceil(exact) : Math.round(exact);
}

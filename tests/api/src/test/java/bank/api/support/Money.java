package bank.api.support;

import java.math.BigDecimal;

public final class Money {
    private Money() {
    }

    /** "10.10" dollars to 1010 minor units. */
    public static long minor(String dollars) {
        return new BigDecimal(dollars).movePointRight(2).longValueExact();
    }
}

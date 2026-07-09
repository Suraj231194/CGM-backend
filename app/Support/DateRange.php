<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use Illuminate\Http\Request;

class DateRange
{
    public function __construct(
        public readonly ?CarbonImmutable $from,
        public readonly ?CarbonImmutable $to,
    ) {}

    public static function fromRequest(Request $request, int $defaultDays = 14): self
    {
        $to = $request->filled('to')
            ? CarbonImmutable::parse($request->query('to'))
            : CarbonImmutable::now();

        $from = $request->filled('from')
            ? CarbonImmutable::parse($request->query('from'))
            : $to->subDays($defaultDays);

        return new self($from, $to);
    }
}

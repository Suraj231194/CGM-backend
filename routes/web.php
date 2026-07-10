<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/up', function () {
    try {
        DB::select('select 1');

        return response()->json([
            'status' => 'ok',
            'database' => 'connected',
        ]);
    } catch (\Throwable $exception) {
        report($exception);

        return response()->json([
            'status' => 'unavailable',
            'database' => 'disconnected',
        ], 503);
    }
});

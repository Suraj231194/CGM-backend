<?php

namespace App\Http\Controllers\Patient;

use App\Http\Controllers\Controller;
use App\Http\Resources\SensorOrderResource;
use App\Models\PatientProfile;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SensorOrderController extends Controller
{
    public function index(PatientProfile $patient): JsonResponse
    {
        return ApiResponse::success([
            'orders' => SensorOrderResource::collection($patient->orders()->latest()->get()),
        ]);
    }

    public function store(Request $request, PatientProfile $patient): JsonResponse
    {
        $data = $request->validate([
            'productName' => ['required', 'string', 'max:255'],
            'quantity' => ['required', 'integer', 'min:1', 'max:24'],
            'shippingAddress' => ['required', 'string', 'max:2000'],
        ]);

        $order = $patient->orders()->create([
            'product_name' => $data['productName'],
            'quantity' => $data['quantity'],
            'shipping_address' => $data['shippingAddress'],
            'status' => 'placed',
        ]);

        return response()->json(new SensorOrderResource($order), 201);
    }
}

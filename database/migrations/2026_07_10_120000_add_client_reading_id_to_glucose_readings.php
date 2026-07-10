<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('glucose_readings', function (Blueprint $table): void {
            $table->string('client_reading_id', 190)->nullable()->after('device_id');
            $table->unique(
                ['patient_id', 'client_reading_id'],
                'glucose_readings_patient_client_unique',
            );
        });

        // Demo readings must never be mixed with measurements from a real CGM.
        DB::table('glucose_readings')->where('source', 'seed')->delete();
    }

    public function down(): void
    {
        Schema::table('glucose_readings', function (Blueprint $table): void {
            $table->dropUnique('glucose_readings_patient_client_unique');
            $table->dropColumn('client_reading_id');
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('type')->default('clinic');
            $table->string('timezone')->default('Asia/Kolkata');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('organization_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('member');
            $table->timestamp('joined_at')->nullable();
            $table->timestamps();
            $table->unique(['organization_id', 'user_id']);
        });

        Schema::create('doctor_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->string('specialty')->nullable();
            $table->string('license_number')->nullable()->unique();
            $table->string('phone')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('patient_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('doctor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->date('date_of_birth')->nullable();
            $table->unsignedTinyInteger('age')->nullable();
            $table->string('gender')->nullable();
            $table->string('phone')->nullable();
            $table->string('risk_level')->default('stable')->index();
            $table->string('medical_record_number')->nullable()->unique();
            $table->text('diagnosis_notes')->nullable();
            $table->string('emergency_contact_name')->nullable();
            $table->string('emergency_contact_phone')->nullable();
            $table->string('preferred_unit')->default('mg/dL');
            $table->timestamps();
            $table->index(['doctor_id', 'risk_level']);
        });

        Schema::create('patient_data_grants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('doctor_id')->nullable()->constrained('users')->cascadeOnDelete();
            $table->foreignId('organization_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('granted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status')->default('accepted')->index();
            $table->json('permissions')->nullable();
            $table->timestamp('granted_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('consent_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('health_data')->default(false);
            $table->boolean('sensor_data')->default(false);
            $table->boolean('ai_coaching')->default(false);
            $table->boolean('report_sharing')->default(false);
            $table->boolean('terms_accepted')->default(false);
            $table->string('status')->default('pending');
            $table->timestamp('consented_at')->nullable();
            $table->timestamps();
        });

        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->nullable()->constrained('patient_profiles')->nullOnDelete();
            $table->string('serial_number')->unique();
            $table->string('model')->default('Optimus CGM 14-day sensor');
            $table->string('manufacturer')->default('Optimus');
            $table->string('status')->default('inactive')->index();
            $table->unsignedTinyInteger('battery_status')->default(100);
            $table->string('connection_status')->default('offline');
            $table->timestamp('activation_date')->nullable();
            $table->timestamp('expiry_date')->nullable();
            $table->timestamp('warmup_start_time')->nullable();
            $table->timestamp('warmup_end_time')->nullable();
            $table->timestamp('last_sync_at')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        Schema::create('sensor_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->string('status')->default('pending')->index();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('warmed_up_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('glucose_readings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('sensor_session_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamp('timestamp')->index();
            $table->unsignedSmallInteger('value');
            $table->string('unit')->default('mg/dL');
            $table->string('trend')->default('steady');
            $table->string('status')->default('normal')->index();
            $table->string('source')->default('mobile');
            $table->json('raw_payload')->nullable();
            $table->timestamps();
            $table->index(['patient_id', 'timestamp']);
        });

        Schema::create('alert_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->unique()->constrained('patient_profiles')->cascadeOnDelete();
            $table->boolean('notifications_enabled')->default(true);
            $table->unsignedSmallInteger('low_threshold')->default(70);
            $table->unsignedSmallInteger('high_threshold')->default(180);
            $table->boolean('quiet_hours_enabled')->default(false);
            $table->unsignedSmallInteger('sensor_disconnect_reminder_minutes')->default(15);
            $table->timestamps();
        });

        Schema::create('glucose_alerts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('glucose_reading_id')->nullable()->constrained()->nullOnDelete();
            $table->string('alert_type')->default('high')->index();
            $table->string('severity')->default('warning')->index();
            $table->string('title');
            $table->text('message');
            $table->unsignedSmallInteger('value')->default(0);
            $table->unsignedSmallInteger('threshold')->default(0);
            $table->boolean('acknowledged')->default(false)->index();
            $table->foreignId('acknowledged_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('acknowledged_at')->nullable();
            $table->timestamp('timestamp')->index();
            $table->timestamps();
        });

        Schema::create('meal_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->timestamp('timestamp')->index();
            $table->string('type')->default('lunch');
            $table->string('title');
            $table->unsignedSmallInteger('net_carbs')->default(0);
            $table->unsignedSmallInteger('protein')->default(0);
            $table->unsignedSmallInteger('fiber')->default(0);
            $table->unsignedSmallInteger('activity_minutes')->default(0);
            $table->unsignedTinyInteger('score')->default(0);
            $table->text('note')->nullable();
            $table->timestamps();
        });

        Schema::create('ai_interpretations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->string('period');
            $table->text('summary');
            $table->json('patterns')->nullable();
            $table->json('recommendations')->nullable();
            $table->text('disclaimer')->nullable();
            $table->string('tone')->default('patient');
            $table->timestamp('generated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('sensor_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->string('product_name');
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->string('status')->default('placed')->index();
            $table->text('shipping_address');
            $table->string('tracking_number')->nullable();
            $table->timestamps();
        });

        Schema::create('report_exports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('period');
            $table->string('format')->default('PDF');
            $table->string('status')->default('ready')->index();
            $table->text('summary');
            $table->string('file_path')->nullable();
            $table->string('csv_path')->nullable();
            $table->string('share_link')->nullable();
            $table->timestamp('date_range_start')->nullable();
            $table->timestamp('date_range_end')->nullable();
            $table->timestamp('generated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('notification_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->timestamp('timestamp')->index();
            $table->string('title');
            $table->text('message');
            $table->string('type');
            $table->boolean('delivered')->default(false);
            $table->string('route')->nullable();
            $table->timestamps();
        });

        Schema::create('clinician_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('note');
            $table->timestamps();
        });

        Schema::create('care_tasks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->string('owner_role')->default('doctor');
            $table->string('status')->default('open')->index();
            $table->string('priority')->default('routine')->index();
            $table->timestamp('due_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('daily_glucose_summaries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained('patient_profiles')->cascadeOnDelete();
            $table->date('summary_date');
            $table->unsignedSmallInteger('average')->default(0);
            $table->unsignedSmallInteger('minimum')->default(0);
            $table->unsignedSmallInteger('maximum')->default(0);
            $table->unsignedTinyInteger('time_in_range')->default(0);
            $table->unsignedSmallInteger('high_count')->default(0);
            $table->unsignedSmallInteger('low_count')->default(0);
            $table->unsignedSmallInteger('reading_count')->default(0);
            $table->decimal('estimated_a1c', 4, 2)->nullable();
            $table->timestamps();
            $table->unique(['patient_id', 'summary_date']);
        });

        Schema::create('device_integrations', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('name');
            $table->string('provider');
            $table->string('category');
            $table->string('status')->default('available');
            $table->text('summary');
            $table->timestamp('last_sync_at')->nullable();
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_role')->nullable();
            $table->string('action')->index();
            $table->string('target_type')->nullable();
            $table->string('target_id')->nullable();
            $table->text('details')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();
            $table->index(['target_type', 'target_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('device_integrations');
        Schema::dropIfExists('daily_glucose_summaries');
        Schema::dropIfExists('care_tasks');
        Schema::dropIfExists('clinician_notes');
        Schema::dropIfExists('notification_records');
        Schema::dropIfExists('report_exports');
        Schema::dropIfExists('sensor_orders');
        Schema::dropIfExists('ai_interpretations');
        Schema::dropIfExists('meal_logs');
        Schema::dropIfExists('glucose_alerts');
        Schema::dropIfExists('alert_settings');
        Schema::dropIfExists('glucose_readings');
        Schema::dropIfExists('sensor_sessions');
        Schema::dropIfExists('devices');
        Schema::dropIfExists('consent_records');
        Schema::dropIfExists('patient_data_grants');
        Schema::dropIfExists('patient_profiles');
        Schema::dropIfExists('doctor_profiles');
        Schema::dropIfExists('organization_members');
        Schema::dropIfExists('organizations');
    }
};

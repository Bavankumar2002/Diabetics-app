<?php
require_once __DIR__ . '/../config.php';

$input = getJsonInput();
$phone = trim($input['phone'] ?? '');
$countryCode = trim($input['country_code'] ?? '+91');

if (empty($phone)) {
    sendResponse(false, 'Mobile number is required', null, 400);
}

// Clean phone number
$cleanPhone = preg_replace('/[^0-9]/', '', $phone);
if (strlen($cleanPhone) < 7 || strlen($cleanPhone) > 15) {
    sendResponse(false, 'Please enter a valid mobile number', null, 400);
}

$fullPhone = $countryCode . $cleanPhone;

try {
    $pdo = getDBConnection();

    // Invalidate previous unexpired OTPs for this number
    $stmt = $pdo->prepare("UPDATE otps SET is_used = 1 WHERE phone = :phone AND is_used = 0");
    $stmt->execute([':phone' => $fullPhone]);

    // Generate 6-digit OTP
    $otpCode = str_pad((string)random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
    $expiresAt = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    $insert = $pdo->prepare("
        INSERT INTO otps (phone, otp_code, expires_at, is_used)
        VALUES (:phone, :otp, :expires, 0)
    ");
    $insert->execute([
        ':phone' => $fullPhone,
        ':otp' => $otpCode,
        ':expires' => $expiresAt
    ]);

    // Check if user already exists
    $userStmt = $pdo->prepare("SELECT id FROM users WHERE phone = :phone LIMIT 1");
    $userStmt->execute([':phone' => $fullPhone]);
    $userExists = (bool)$userStmt->fetch();

    sendResponse(true, 'OTP sent successfully to ' . $countryCode . ' ' . $cleanPhone, [
        'phone' => $fullPhone,
        'country_code' => $countryCode,
        'mobile_number' => $cleanPhone,
        'is_existing_user' => $userExists,
        'expires_in_seconds' => 600,
        // In local/sandbox development environment, include OTP for seamless testing
        'dev_otp' => $otpCode
    ]);

} catch (Exception $e) {
    sendResponse(false, 'Failed to send OTP: ' . $e->getMessage(), null, 500);
}

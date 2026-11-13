<?php
require_once __DIR__ . '/../config.php';

$input = getJsonInput();
$phone = trim($input['phone'] ?? '');
$otp = trim($input['otp'] ?? '');
$countryCode = trim($input['country_code'] ?? '+91');

if (empty($phone) || empty($otp)) {
    sendResponse(false, 'Mobile number and OTP are required', null, 400);
}

$cleanPhone = preg_replace('/[^0-9]/', '', $phone);
$fullPhone = strpos($phone, '+') === 0 ? $phone : ($countryCode . $cleanPhone);

try {
    $pdo = getDBConnection();

    // Verify OTP
    $stmt = $pdo->prepare("
        SELECT id, otp_code, expires_at 
        FROM otps 
        WHERE phone = :phone AND is_used = 0 
        ORDER BY id DESC LIMIT 1
    ");
    $stmt->execute([':phone' => $fullPhone]);
    $otpRecord = $stmt->fetch();

    if (!$otpRecord) {
        sendResponse(false, 'No OTP requested for this number. Please request a new OTP.', null, 400);
    }

    if (strtotime($otpRecord['expires_at']) < time()) {
        sendResponse(false, 'OTP has expired. Please request a new one.', null, 400);
    }

    if ($otpRecord['otp_code'] !== $otp) {
        sendResponse(false, 'Invalid OTP code. Please check and try again.', null, 400);
    }

    // Mark OTP as used
    $updateOtp = $pdo->prepare("UPDATE otps SET is_used = 1 WHERE id = :id");
    $updateOtp->execute([':id' => $otpRecord['id']]);

    // Find or create user
    $userStmt = $pdo->prepare("SELECT * FROM users WHERE phone = :phone LIMIT 1");
    $userStmt->execute([':phone' => $fullPhone]);
    $user = $userStmt->fetch();

    $token = bin2hex(random_bytes(32));

    if (!$user) {
        $insertUser = $pdo->prepare("
            INSERT INTO users (phone, country_code, is_verified, auth_token)
            VALUES (:phone, :country_code, 1, :token)
        ");
        $insertUser->execute([
            ':phone' => $fullPhone,
            ':country_code' => $countryCode,
            ':token' => $token
        ]);
        $userId = $pdo->lastInsertId();
        $isOnboarded = false;
        $profile = null;
    } else {
        $userId = $user['id'];
        $updateUser = $pdo->prepare("UPDATE users SET auth_token = :token, is_verified = 1 WHERE id = :id");
        $updateUser->execute([':token' => $token, ':id' => $userId]);

        // Check if onboarding profile exists
        $profileStmt = $pdo->prepare("SELECT * FROM user_profiles WHERE user_id = :uid LIMIT 1");
        $profileStmt->execute([':uid' => $userId]);
        $profile = $profileStmt->fetch();
        $isOnboarded = ($profile !== false);
    }

    sendResponse(true, 'Authentication successful', [
        'auth_token' => $token,
        'user_id' => (int)$userId,
        'phone' => $fullPhone,
        'is_onboarded' => $isOnboarded,
        'profile' => $profile
    ]);

} catch (Exception $e) {
    sendResponse(false, 'OTP verification failed: ' . $e->getMessage(), null, 500);
}

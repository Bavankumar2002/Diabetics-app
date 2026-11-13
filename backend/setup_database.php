<?php
// Setup Database for Diacare
require_once __DIR__ . '/config.php';

try {
    // 1. Connect without DB
    $rootPdo = new PDO("mysql:host=" . DB_HOST . ";port=" . DB_PORT, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);

    $rootPdo->exec("CREATE DATABASE IF NOT EXISTS " . DB_NAME . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    echo "Database '" . DB_NAME . "' created or already exists.\n";

    // 2. Connect to the DB
    $pdo = getDBConnection();

    // 3. Create tables
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone VARCHAR(20) NOT NULL UNIQUE,
            country_code VARCHAR(8) DEFAULT '+91',
            is_verified TINYINT(1) DEFAULT 0,
            auth_token VARCHAR(128) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS otps (
            id INT AUTO_INCREMENT PRIMARY KEY,
            phone VARCHAR(20) NOT NULL,
            otp_code VARCHAR(10) NOT NULL,
            expires_at DATETIME NOT NULL,
            is_used TINYINT(1) DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_phone (phone)
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS user_profiles (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL UNIQUE,
            name VARCHAR(100) NOT NULL,
            age INT NOT NULL,
            gender VARCHAR(30) NOT NULL,
            country VARCHAR(60) DEFAULT 'India',
            state VARCHAR(60) DEFAULT '',
            district VARCHAR(60) DEFAULT '',
            city VARCHAR(60) DEFAULT '',
            pincode VARCHAR(20) DEFAULT '',
            height_cm DECIMAL(5,2) DEFAULT 170.0,
            weight_kg DECIMAL(5,2) DEFAULT 70.0,
            activity_level VARCHAR(50) DEFAULT 'Moderately Active',
            health_goals TEXT,
            food_preference VARCHAR(50) DEFAULT 'Vegetarian',
            allergies TEXT,
            dietary_restrictions TEXT,
            sleep_hours DECIMAL(3,1) DEFAULT 7.5,
            sleep_quality VARCHAR(50) DEFAULT 'Good',
            water_goal_ml INT DEFAULT 2500,
            step_goal INT DEFAULT 8000,
            exercise_goal_mins INT DEFAULT 30,
            calorie_goal INT DEFAULT 1800,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS diabetes_details (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL UNIQUE,
            diabetes_type VARCHAR(50) NOT NULL,
            diagnosis_date VARCHAR(50) DEFAULT '',
            duration_years VARCHAR(50) DEFAULT '',
            family_history TINYINT(1) DEFAULT 0,
            comorbidities TEXT,
            current_fasting_glucose DECIMAL(6,2) NULL,
            current_post_meal_glucose DECIMAL(6,2) NULL,
            current_hba1c DECIMAL(4,2) NULL,
            last_hba1c_date DATE NULL,
            target_glucose_min DECIMAL(6,2) DEFAULT 70.0,
            target_glucose_max DECIMAL(6,2) DEFAULT 140.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS glucose_readings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            reading_value DECIMAL(6,2) NOT NULL,
            meal_type VARCHAR(50) NOT NULL,
            unit VARCHAR(10) DEFAULT 'mg/dL',
            measured_at DATETIME NOT NULL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_date (user_id, measured_at),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS food_items (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(120) NOT NULL,
            category VARCHAR(60) NOT NULL,
            meal_slot VARCHAR(60) NOT NULL,
            serving_size VARCHAR(60) NOT NULL,
            calories DECIMAL(6,2) NOT NULL,
            protein DECIMAL(6,2) NOT NULL,
            carbs DECIMAL(6,2) NOT NULL,
            fat DECIMAL(6,2) NOT NULL,
            fiber DECIMAL(6,2) NOT NULL,
            is_diabetes_friendly TINYINT(1) DEFAULT 1,
            diet_type VARCHAR(30) DEFAULT 'Vegetarian',
            is_low_carb TINYINT(1) DEFAULT 0,
            is_high_fiber TINYINT(1) DEFAULT 0,
            is_high_protein TINYINT(1) DEFAULT 0,
            description TEXT,
            image_url VARCHAR(255) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS food_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            meal_time VARCHAR(40) NOT NULL,
            food_item_id INT NULL,
            custom_name VARCHAR(120) NULL,
            quantity DECIMAL(4,2) DEFAULT 1.0,
            serving_size VARCHAR(60),
            calories DECIMAL(6,2) NOT NULL,
            protein DECIMAL(6,2) NOT NULL,
            carbs DECIMAL(6,2) NOT NULL,
            fat DECIMAL(6,2) NOT NULL,
            fiber DECIMAL(6,2) NOT NULL,
            logged_date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_logdate (user_id, logged_date),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS medication (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            name VARCHAR(120) NOT NULL,
            dosage VARCHAR(60) NOT NULL,
            frequency VARCHAR(60) NOT NULL,
            is_insulin TINYINT(1) DEFAULT 0,
            start_date DATE NULL,
            end_date DATE NULL,
            reminder_time VARCHAR(20) NOT NULL,
            instructions VARCHAR(255) NULL,
            is_active TINYINT(1) DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS medication_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            medication_id INT NOT NULL,
            user_id INT NOT NULL,
            scheduled_time VARCHAR(20),
            status VARCHAR(20) NOT NULL DEFAULT 'taken',
            logged_date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_meddate (user_id, logged_date),
            FOREIGN KEY (medication_id) REFERENCES medication(id) ON DELETE CASCADE,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS water_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            amount_ml INT NOT NULL,
            logged_date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_waterdate (user_id, logged_date),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS activity_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            activity_type VARCHAR(60) NOT NULL,
            steps INT DEFAULT 0,
            duration_mins INT NOT NULL,
            calories_burned INT NOT NULL,
            logged_date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_activitydate (user_id, logged_date),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS reminders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            reminder_type VARCHAR(60) NOT NULL,
            title VARCHAR(120) NOT NULL,
            reminder_time VARCHAR(20) NOT NULL,
            is_enabled TINYINT(1) DEFAULT 1,
            days_of_week VARCHAR(60) DEFAULT 'all',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS ai_chat_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            role VARCHAR(20) NOT NULL,
            message TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_chat (user_id, created_at),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB;
    ");

    echo "All tables verified and created successfully.\n";

    // 4. Seed food items if empty
    $countStmt = $pdo->query("SELECT COUNT(*) FROM food_items");
    if ($countStmt->fetchColumn() == 0) {
        $foods = [
            // Breakfast
            ['Steamed Idli with Sambar', 'South Indian', 'Breakfast', '2 Idlis (100g) + 1 Cup Sambar', 160, 6.5, 30, 1.2, 4.5, 1, 'Vegetarian', 0, 1, 0, 'Fermented rice and lentil cakes steamed, served with vegetable lentil stew.'],
            ['Ragi Dosa with Mint Chutney', 'South Indian', 'Breakfast', '1 Medium Dosa (80g)', 135, 4.2, 22, 2.8, 5.2, 1, 'Vegetarian', 1, 1, 0, 'Finger millet crepe rich in calcium and complex carbohydrates with low glycemic response.'],
            ['Oats Vegetable Upma', 'Breakfast', 'Breakfast', '1 Bowl (150g)', 180, 5.5, 26, 4.0, 6.0, 1, 'Vegetarian', 0, 1, 0, 'Rolled oats cooked with carrots, green peas, beans, mustard seeds and curry leaves.'],
            ['Moong Dal Chilla with Curd', 'Breakfast', 'Breakfast', '2 Small Chillas (100g)', 190, 11.0, 24, 3.5, 5.0, 1, 'Vegetarian', 0, 1, 1, 'Savory split yellow gram pancakes packed with plant protein.'],
            ['Boiled Egg Whites with Spinach', 'Breakfast', 'Breakfast', '2 Egg Whites + Spinach (120g)', 85, 9.5, 2, 0.5, 1.8, 1, 'Eggetarian', 1, 0, 1, 'High protein, almost zero carb morning meal ideal for blood sugar management.'],
            ['Multigrain Methi Thepla', 'Breakfast', 'Breakfast', '2 Pieces (80g)', 175, 5.0, 25, 4.2, 4.8, 1, 'Vegetarian', 0, 1, 0, 'Whole wheat and fenugreek flatbreads known for insulin sensitizing properties.'],
            
            // Morning Snack
            ['Sprouted Moong Salad', 'Snack', 'Morning Snack', '1 Cup (120g)', 110, 7.5, 16, 0.8, 4.2, 1, 'Vegetarian', 0, 1, 1, 'Fresh mung bean sprouts tossed with cucumber, lemon juice, chaat masala.'],
            ['Roasted Chana (Chickpeas)', 'Snack', 'Morning Snack', 'Handful (40g)', 140, 7.0, 21, 2.2, 5.5, 1, 'Vegetarian', 0, 1, 1, 'Crunchy dry roasted chickpeas with a very low glycemic index.'],
            ['Soaked Almonds & Walnuts', 'Nuts', 'Morning Snack', '6 Almonds + 2 Walnuts (20g)', 125, 3.5, 3.0, 11.0, 2.0, 1, 'Vegetarian', 1, 0, 0, 'Packed with healthy monounsaturated fats that stabilize morning glucose levels.'],
            ['Greek Yogurt with Chia Seeds', 'Snack', 'Morning Snack', '1 Small Bowl (120g)', 105, 10.0, 6.0, 2.5, 2.5, 1, 'Vegetarian', 1, 0, 1, 'Probiotic rich yogurt sprinkled with omega-3 rich chia seeds.'],

            // Lunch
            ['Whole Wheat Chapati with Dal Tadka', 'North Indian', 'Lunch', '2 Chapatis + 1 Cup Dal', 290, 12.0, 48, 5.5, 8.0, 1, 'Vegetarian', 0, 1, 1, 'Whole wheat rotis paired with yellow lentil soup tempered with cumin and garlic.'],
            ['Brown Rice with Sambar & Avial', 'South Indian', 'Lunch', '1 Cup Rice (150g) + Veggies', 320, 8.5, 55, 6.0, 7.5, 1, 'Vegetarian', 0, 1, 0, 'Unpolished high-fiber brown rice accompanied by mixed vegetable stew and coconut yogurt curry.'],
            ['Grilled Chicken Breast with Steamed Veggies', 'Continental', 'Lunch', '150g Chicken + 100g Veg', 260, 32.0, 8.0, 5.0, 3.5, 1, 'Non-vegetarian', 1, 0, 1, 'Lean chicken breast seasoned with herbs, broccoli, beans, and bell peppers.'],
            ['Palak Paneer with Multigrain Roti', 'North Indian', 'Lunch', '1 Cup Paneer + 2 Rotis', 340, 16.0, 36, 14.0, 7.0, 1, 'Vegetarian', 0, 1, 1, 'Fresh cottage cheese simmered in smooth spinach gravy, rich in iron and protein.'],
            ['Fish Curry (Kerala Style) with Red Rice', 'South Indian', 'Lunch', '1 Slice Fish + 1 Cup Red Rice', 310, 24.0, 42, 6.5, 5.0, 1, 'Non-vegetarian', 0, 1, 1, 'Nutrient-dense Matta red rice served with omega-3 rich fish curry cooked in mild spices.'],
            ['Quinoa Khichdi with Mixed Veggies', 'Indian Healthy', 'Lunch', '1 Large Bowl (200g)', 240, 9.0, 38, 4.5, 6.5, 1, 'Vegetarian', 0, 1, 0, 'Complete protein grain cooked with yellow moong dal, ginger, and diced vegetables.'],

            // Evening Snack
            ['Roasted Makhana (Foxnuts)', 'Snack', 'Evening Snack', '1 Bowl (30g)', 105, 3.0, 20, 0.5, 2.5, 1, 'Vegetarian', 0, 0, 0, 'Light, crunchy lotus seeds roasted with turmeric and rock salt.'],
            ['Cucumber and Tomato Slices with Hummus', 'Snack', 'Evening Snack', '1 Plate (150g)', 120, 4.5, 12, 6.0, 4.0, 1, 'Vegan', 1, 1, 0, 'Crisp refreshing raw vegetables paired with chickpea tahini dip.'],
            ['Green Tea with Roasted Pumpkin Seeds', 'Beverage', 'Evening Snack', '1 Cup Tea + 15g Seeds', 85, 4.0, 2.5, 7.0, 1.5, 1, 'Vegan', 1, 0, 0, 'Antioxidant rich green tea without sugar plus zinc-rich pumpkin seeds.'],
            ['Boiled Chana Chaat', 'Snack', 'Evening Snack', '1 Cup (120g)', 155, 7.5, 23, 2.0, 5.0, 1, 'Vegetarian', 0, 1, 1, 'Boiled black chickpeas with chopped onions, tomatoes, and coriander.'],

            // Dinner
            ['Vegetable Clear Soup with Tofu Stir-fry', 'Dinner', 'Dinner', '1 Bowl Soup + 100g Tofu', 180, 14.0, 10, 7.0, 4.0, 1, 'Vegan', 1, 1, 1, 'Light, comforting vegetable broth followed by pan-seared tofu and bok choy.'],
            ['Bajra (Pearl Millet) Roti with Baingan Bharta', 'Dinner', 'Dinner', '1 Bajra Roti + 1 Cup Bharta', 220, 6.0, 34, 5.5, 7.0, 1, 'Vegetarian', 0, 1, 0, 'Gluten-free pearl millet roti paired with roasted eggplant mash.'],
            ['Grilled Fish Fillet with Asparagus & Salad', 'Dinner', 'Dinner', '140g Fish + Mixed Salad', 210, 28.0, 5.0, 6.0, 3.0, 1, 'Non-vegetarian', 1, 0, 1, 'Zero-carb protein with light fiber to prevent nocturnal blood sugar spikes.'],
            ['Methi Roti with Lauki (Bottle Gourd) Sabzi', 'Dinner', 'Dinner', '2 Rotis + 1 Cup Sabzi', 230, 6.5, 38, 4.5, 6.5, 1, 'Vegetarian', 0, 1, 0, 'Calming, easy-to-digest dinner gentle on nighttime digestion and blood glucose.'],
            ['Paneer Tikka with Green Salad', 'Dinner', 'Dinner', '5 Cubes (120g) + Salad', 250, 18.0, 9.0, 14.0, 3.0, 1, 'Vegetarian', 1, 0, 1, 'Marinated spiced cottage cheese baked to perfection with capsicum and onion.']
        ];

        $insertFood = $pdo->prepare("
            INSERT INTO food_items (name, category, meal_slot, serving_size, calories, protein, carbs, fat, fiber, is_diabetes_friendly, diet_type, is_low_carb, is_high_fiber, is_high_protein, description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");

        foreach ($foods as $f) {
            $insertFood->execute($f);
        }
        echo "Seeded " . count($foods) . " diabetes-friendly Indian foods successfully.\n";
    }

    echo "Database setup completed successfully.\n";

} catch (Exception $e) {
    echo "Setup Error: " . $e->getMessage() . "\n";
    exit(1);
}

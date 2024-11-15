<?php
// Database connection details
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "berwehsan";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Validate and retrieve 'id' parameter from the URL
if (isset($_GET['id']) && is_numeric($_GET['id'])) {
    $caseId = (int) $_GET['id']; // Explicitly cast to integer for safety

    // Fetch case data
    $stmt = $conn->prepare("SELECT * FROM cases WHERE id = ?");
    $stmt->bind_param("i", $caseId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $caseData = $result->fetch_assoc();
    } else {
        die("<div style='color: red; text-align: center;'>Case not found in the database!</div>"); // Handle case not found
    }

    $stmt->close(); // Close the statement
} else {
    die("<div style='color: red; text-align: center;'>Invalid case ID!</div>"); // Handle invalid or missing ID
}
?>
<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تعديل بيانات حالة</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            direction: rtl;
            font-family: 'Arial', sans-serif;
        }
        .container {
            margin-top: 50px;
        }
        .form-group label {
            font-weight: bold;
        }
    </style>
</head>
<body>
<div class="container">
    <h2 class="text-center mb-4">تعديل بيانات حالة</h2>
    <form action="update_case.php" method="POST">
        <input type="hidden" name="id" value="<?php echo htmlspecialchars($caseId); ?>">

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="case_name">اسم الحالة</label>
                <input type="text" class="form-control" id="case_name" name="case_name" value="<?php echo htmlspecialchars($caseData['name']); ?>" placeholder="اسم الحالة">
            </div>
            <div class="form-group col-md-6">
                <label for="most_area">العنوان</label>
                <input type="text" class="form-control" id="most_area" name="most_area" value="<?php echo htmlspecialchars($caseData['location']); ?>" placeholder="العنوان">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="most_box">أكثر الصندوق</label>
                <input type="text" class="form-control" id="most_box" name="most_box" value="<?php echo htmlspecialchars($caseData['chest_id'] ?? ''); ?>" placeholder="أكثر الصندوق">
            </div>
            <div class="form-group col-md-6">
                <label for="family_members">رقم العائلة</label>
                <input type="number" class="form-control" id="family_members" name="family_members" value="<?php echo htmlspecialchars($caseData['family_id'] ?? ''); ?>" placeholder="رقم العائلة">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="clothes_size">مقاس الملابس</label>
                <input type="text" class="form-control" id="clothes_size" name="clothes_size" value="<?php echo htmlspecialchars($caseData['c_size'] ?? ''); ?>" placeholder="مقاس الملابس">
            </div>
            <div class="form-group col-md-6">
                <label for="phone_number">رقم الهاتف</label>
                <input type="text" class="form-control" id="phone_number" name="phone_number" value="<?php echo htmlspecialchars($caseData['number'] ?? ''); ?>" placeholder="رقم الهاتف">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="national_id">الرقم القومي</label>
                <input type="text" class="form-control" id="national_id" name="national_id" value="<?php echo htmlspecialchars($caseData['ID_Number'] ?? ''); ?>" placeholder="الرقم القومي">
            </div>
            <div class="form-group col-md-6">
                <label for="school_stage">المرحلة الدراسية</label>
                <input type="text" class="form-control" id="school_stage" name="school_stage" value="<?php echo htmlspecialchars($caseData['source'] ?? ''); ?>" placeholder="المرحلة الدراسية">
            </div>
        </div>

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="shoe_size">مقاس الحذاء</label>
                <input type="number" class="form-control" id="shoe_size" name="shoe_size" value="<?php echo htmlspecialchars($caseData['S_size'] ?? ''); ?>" placeholder="مقاس الحذاء">
            </div>
            <div class="form-group col-md-6">
                <label for="social_status">الحالة الاجتماعية</label>
                <select id="social_status" name="social_status" class="form-control">
                    <option <?php echo (isset($caseData['social_status']) && $caseData['social_status'] === 'أرملة') ? 'selected' : ''; ?>>أرملة</option>
                    <option <?php echo (isset($caseData['social_status']) && $caseData['social_status'] === 'متزوجة') ? 'selected' : ''; ?>>متزوجة</option>
                    <option <?php echo (isset($caseData['social_status']) && $caseData['social_status'] === 'عزباء') ? 'selected' : ''; ?>>عزباء</option>
                </select>
            </div>
        </div>

        <div class="form-row">
            <div class="form-group col-md-6">
                <label for="feeding_times">عدد مرات أطعام الأسرة</label>
                <input type="number" class="form-control" id="feeding_times" name="feeding_times" value="<?php echo htmlspecialchars($caseData['food_times'] ?? ''); ?>" placeholder="عدد مرات أطعام الأسرة">
            </div>
        </div>

        <div class="text-center mt-4">
            <button type="submit" class="btn btn-primary">تحديث</button>
            <button type="button" class="btn btn-warning" onclick="window.history.back();">تراجع</button>
        </div>
    </form>
</div>

<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

</body>
</html>

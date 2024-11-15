<?php
// Database connection setup
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

// Get area_id from URL and validate it
$area_id = isset($_GET['id']) ? (int)$_GET['id'] : NULL;

// Check if area_id is valid
if ($area_id === NULL) {
    die("<p style='color: red; text-align: center;'>لم يتم تقديم معرف المنطقة بشكل صحيح أو هو غير صالح.</p>");
}

// Check if form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get selected case name and amount from the form
    $case_name = isset($_POST['case_name']) ? $conn->real_escape_string($_POST['case_name']) : '';
    $amount = isset($_POST['amount']) && $_POST['amount'] !== '' ? (float)$_POST['amount'] : NULL;

    // Update the balance for the selected case in the specific area
    if ($case_name && $amount !== NULL) {
        $sql = "UPDATE cases SET balance = balance + $amount WHERE name = '$case_name' AND area_id = $area_id";
        if ($conn->query($sql) === TRUE) {
            echo "<p style='color: green; text-align: center;'>تم تسجيل القبض بنجاح وتم تحديث الرصيد.</p>";
        } else {
            echo "<p style='color: red; text-align: center;'>خطأ: " . $conn->error . "</p>";
        }
    } else {
        echo "<p style='color: red; text-align: center;'>الرجاء اختيار حالة وإدخال قيمة القبض.</p>";
    }
}

// Fetch cases for the dropdown based on area_id
$sql = "SELECT name FROM cases WHERE area_id = $area_id";
$result = $conn->query($sql);

// If area_id was invalid or there are no cases for that area, handle gracefully
if (!$result) {
    die("<p style='color: red; text-align: center;'>خطأ في جلب الحالات. تأكد من معرف المنطقة.</p>");
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>قبض الحالات</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        body { font-family: 'Cairo', sans-serif; direction: rtl; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group select, .form-group input { width: 100%; padding: 10px; font-size: 16px; border: 1px solid #ddd; border-radius: 5px; }
        .form-footer { display: flex; justify-content: space-between; }
        .form-footer button { padding: 10px 20px; font-size: 16px; border: none; border-radius: 5px; cursor: pointer; }
        .form-footer .save-btn { background-color: #4CAF50; color: white; }
        .form-footer .cancel-btn { background-color: #f44336; color: white; }
    </style>
</head>
<body>

<div class="container">
    <h2>تسجيل القبض</h2>
    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]) . '?id=' . $area_id; ?>" method="POST">
        <!-- Dropdown to select case -->
        <div class="form-group">
            <label for="case_name">اختر الحالة</label>
            <select name="case_name" id="case_name" required>
                <option value="">اختر حالة</option>
                <?php
                if ($result->num_rows > 0) {
                    while ($row = $result->fetch_assoc()) {
                        echo "<option value='" . htmlspecialchars($row['name']) . "'>" . htmlspecialchars($row['name']) . "</option>";
                    }
                } else {
                    echo "<option value=''>لا توجد حالات متاحة لهذه المنطقة</option>";
                }
                ?>
            </select>
        </div>
        
        <!-- Input for amount -->
        <div class="form-group">
            <label for="amount">قيمة القبض</label>
            <input type="number" name="amount" id="amount" placeholder="0" step="0.01" required>
        </div>
        
        <!-- Action buttons -->
        <div class="form-footer">
            <button type="button" class="cancel-btn" onclick="window.history.back();">تراجع</button>
            <button type="submit" class="save-btn">حفظ</button>
        </div>
    </form>
</div>

</body>
</html>

<?php
// Close the database connection
$conn->close();
?>

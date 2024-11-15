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

// Validate and fetch id from URL
if (!isset($_GET['id']) || !is_numeric($_GET['id']) || $_GET['id'] <= 0) {
    die("Invalid case ID in the URL. Please provide a valid case ID.");
}
$case_id = (int)$_GET['id'];

// Fetch case details from cases table
$case_query = "SELECT * FROM cases WHERE id = $case_id";
$case_result = $conn->query($case_query);

if (!$case_result) {
    die("Database query failed: " . $conn->error);
}

if ($case_result->num_rows > 0) {
    $case = $case_result->fetch_assoc(); // Fetch case details
} else {
    die("Case not found in the database.");
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $credit = isset($_POST['credit']) ? (int)$_POST['credit'] : 0;
    $status = 'in'; // Set status to 'in' for a new cash entry

    // Insert into cashs table
    $insert_query = "INSERT INTO cashs (case_id, sub_id, credit, status, created_at, updated_at) 
                     VALUES ($case_id, 0, $credit, 'out', NOW(), NOW())";

    if ($conn->query($insert_query) === TRUE) {
        $message = "تم تسجيل القبض بنجاح.";
    } else {
        $message = "خطأ أثناء تسجيل القبض: " . $conn->error;
    }
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تسجيل قبض</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            direction: rtl;
            font-family: 'Arial', sans-serif;
        }
        .container {
            margin-top: 50px;
        }
    </style>
</head>
<body>
<div class="container">
    <h3 class="text-center">تسجيل قبض</h3>

    <!-- Display case details -->
    <div class="card mb-4">
        <div class="card-header">بيانات الحالة</div>
        <div class="card-body">
            <table class="table table-bordered">
                <tr>
                    <th>رقم الحالة</th>
                    <td><?= htmlspecialchars($case['id']) ?></td>
                </tr>
                <tr>
                    <th>رصيد الحالة</th>
                    <td><?= htmlspecialchars($case['balance']) ?></td>
                </tr>
            </table>
        </div>
    </div>

    <!-- Form to register new cash -->
    <div class="card mb-4">
        <div class="card-header">تسجيل مبلغ قبض</div>
        <div class="card-body">
            <?php if (!empty($message)): ?>
                <div class="alert alert-success"><?= htmlspecialchars($message) ?></div>
            <?php endif; ?>
            <form method="POST">
                <div class="form-group">
                    <label for="credit">المبلغ</label>
                    <input type="number" name="credit" id="credit" class="form-control" required>
                </div>
                <button type="submit" class="btn btn-primary">تسجيل</button>
            </form>
        </div>
    </div>
</div>

<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>

<?php
$conn->close();
?>

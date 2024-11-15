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

// Fetch today's payment for the given case_id
$today_date = date('Y-m-d');
$payment_query = "SELECT * FROM cashs WHERE case_id = $case_id AND DATE(created_at) = '$today_date'";
$payment_result = $conn->query($payment_query);

if ($payment_result && $payment_result->num_rows > 0) {
    $payment = $payment_result->fetch_assoc(); // Get today's payment details
} else {
    die("No payment found for today.");
}

// Fetch case details
$case_query = "SELECT * FROM cases WHERE id = $case_id";
$case_result = $conn->query($case_query);

if ($case_result && $case_result->num_rows > 0) {
    $case = $case_result->fetch_assoc();
} else {
    die("Case not found.");
}

// QR Code path
$qr_folder = "qrcodes";
$qr_file_path = $qr_folder . "/" . $case_id . ".png";

if (!file_exists($qr_file_path)) {
    die("QR code not found for this case.");
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>طباعة QR</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            direction: rtl;
            font-family: 'Arial', sans-serif;
        }
        .container {
            margin-top: 50px;
            text-align: center;
        }
        .receipt {
            border: 1px solid #000;
            padding: 20px;
            width: 300px;
            margin: 0 auto;
        }
        .receipt h3 {
            margin-bottom: 20px;
        }
        .qr-code {
            margin: 20px 0;
        }
        @media print {
            .btn {
                display: none;
            }
        }
    </style>
</head>
<body>
<div class="container">
    <div class="receipt">
        <h3>إيصال الدفع</h3>
        <p><strong>رقم الحالة:</strong> <?= htmlspecialchars($case['id']) ?></p>
        <p><strong>اسم الحالة:</strong> <?= htmlspecialchars($case['name']) ?></p>
        <p><strong>المبلغ:</strong> <?= htmlspecialchars($payment['credit']) ?> جنيه</p>
        <p><strong>التاريخ:</strong> <?= date('Y-m-d H:i:s') ?></p>
        <div class="qr-code">
            <img src="<?= htmlspecialchars($qr_file_path) ?>" alt="QR Code" width="150">
        </div>
    </div>
    <button class="btn btn-primary" onclick="window.print()">طباعة الإيصال</button>
</div>

<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>

<?php
// Close database connection
$conn->close();
?>

<?php
// Include the PHP QR Code library
require 'qrcode/qrlib.php';

// Database connection details
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "berwehsan";
$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch case details
$case_id = isset($_GET['id']) ? (int)$_GET['id'] : 0; // Ensure case ID is an integer

// Check if $case_id is valid
if ($case_id > 0) {
    $case_query = "SELECT * FROM cases WHERE id = $case_id";
    $case_result = $conn->query($case_query);

    // Check if the case exists
    if ($case_result && $case_result->num_rows > 0) {
        $case = $case_result->fetch_assoc();

        // Retrieve the family_id from the case record
        $family_id = $case['family_id'];

        // Query to fetch all family members with the provided family_id
        $family_query = "SELECT * FROM cases WHERE family_id = $family_id";
        $family_result = $conn->query($family_query);
        $family_members = $family_result->fetch_all(MYSQLI_ASSOC);

        // Fetch monthly payments associated with this case
        $payments_query = "SELECT * FROM cashs WHERE case_id = $case_id";
        $payments_result = $conn->query($payments_query);
        $payments = $payments_result->fetch_all(MYSQLI_ASSOC);


        // Define QR folder and file path
        $qrFolder = "qrcodes"; // Folder where QR codes are stored
        $qrFilePath = $qrFolder . "/" . $case_id . ".png"; // e.g., qrcodes/123.png

        // Check if the QR code file exists; if not, generate it
        if (!file_exists($qrFilePath)) {
            // Create the directory if it doesn't exist
            if (!is_dir($qrFolder)) {
                mkdir($qrFolder, 0755, true);
            }

            // Data to encode in the QR code (customize as needed)
            $qrData = "http://localhost/البروالاحسان/ملف_الحالة.php?id=" . $case['id'];

            // Generate and save the QR code
            QRcode::png($qrData, $qrFilePath);
        }
    } else {
        die("Case not found.");
    }
} else {
    die("Invalid case ID.");
}
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ملف الحالة</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            direction: rtl;
            font-family: 'Arial', sans-serif;
        }
        .container {
            margin-top: 50px;
        }
        .section-title {
            font-weight: bold;
            margin-top: 20px;
        }
        .table-responsive {
            margin-top: 20px;
        }
        .qr-code {
            text-align: center;
            margin: 20px 0;
        }
    </style>
</head>
<body>
<div class="container">
    <h3 class="text-center">ملف الحالة</h3>

    <!-- Case Information Section -->
    <div class="card mb-4">
        <div class="card-header">بيانات الحالة</div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-bordered">
                    <tr>
                        <th>رقم الحالة</th><td><?= htmlspecialchars($case['id']) ?></td>
                        <th>الاسم</th><td><?= htmlspecialchars($case['name']) ?></td>
                    </tr>
                    <tr>
                        <th>الرقم القومي</th><td><?= htmlspecialchars($case['ID_Number']) ?></td>
                        <th>رقم الهاتف</th><td><?= htmlspecialchars($case['number']) ?></td>
                    </tr>
                    <tr>
                        <th>رقم العائلة</th><td><?= htmlspecialchars($case['family_id']) ?></td>
                        <th>الصندوق</th><td><?= htmlspecialchars($case['chest_id']) ?></td>
                    </tr>
                    <tr>
                        <th>العنوان</th><td><?= htmlspecialchars($case['location']) ?></td>
                        <th>قبض حالة</th><td><?= htmlspecialchars($case['balance']) ?></td>
                    </tr>
                </table>
            </div>
        </div>
    </div>

    <!-- Family Information Section -->
   <!-- Family Information Section -->
<div class="card mb-4">
    <div class="card-header">بيانات أولاد الحالة</div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-bordered">
                <thead>
                    <tr>
                        <th>الاسم</th>
                        <th>الرقم القومي</th>
                        <th>العمر</th>
                        <th>الحالة الاجتماعية</th>
                        <th>الدخل</th>
                        <th>المصدر</th>
                        <th>الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($family_members) || $case['family_id'] == 0): ?>
                        <tr>
                            <td colspan="7" class="text-center">لا يوجد أفراد في الأسرة</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($family_members as $member): ?>
                        <tr>
                            <td><?= htmlspecialchars($member['name']) ?></td>
                            <td><?= htmlspecialchars($member['ID_Number']) ?></td>
                            <td><?= htmlspecialchars($member['age']) ?></td>
                            <td><?= htmlspecialchars($member['social_status']) ?></td>
                            <td><?= htmlspecialchars($member['balance']) ?></td>
                            <td><?= htmlspecialchars($member['student_chest'] ?? 'لا يوجد') ?></td>
                            <td><?= htmlspecialchars($member['status'] ?? 'غير مسجل') ?></td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>


    <!-- QR Code Section -->
    <div class="card mb-4">
        <div class="card-header">QR كود</div>
        <div class="card-body text-center">
            <?php
            // Display the QR code image
            echo '<img src="' . htmlspecialchars($qrFilePath) . '" alt="QR Code">';
            ?>
            <div class="mt-2">
                <a href="طباعة QR.php?id=<?= $case_id ?>" class="btn btn-primary">طباعة QR</a>
                <a href="تسجيل قبض.php?id=<?= $case_id ?>" class="btn btn-success">تسجيل قبض</a>
            </div>
        </div>
    </div>

    <!-- Case Summary Section -->
    <div class="card mb-4">
        <div class="card-header">ملخص الحالة</div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-bordered">
                    <tr><th>الحالة</th><td><?= htmlspecialchars($case['status'] ?? '') ?></td></tr>
                    <tr><th>اليوم</th><td><?= date('Y-m-d', strtotime($case['created_at'])) ?></td></tr>
                </table>
            </div>
        </div>
    </div>

    <!-- Monthly Payments Section -->
    <div class="card mb-4">
        <div class="card-header">الدفع الشهري</div>
        <div class="card-body">
            <div class="table-responsive">
                <table class="table table-bordered">
                    <thead>
                        <tr>
                            <th>الشهر</th>
                            <th>قيمة الفحص</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($payments as $payment): ?>
                        <tr>
                            <td><?= htmlspecialchars($payment['created_at']) ?></td>
                            <td><?= htmlspecialchars($payment['credit']) ?></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
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

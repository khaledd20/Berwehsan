<?php
// Database connection details (replace with your own credentials)
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "berwehsan";

// Create connection to the MySQL database
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Define variables and initialize with empty values
$amount = $receipt = $comment = "";
$amount_err = $receipt_err = $comment_err = "";

// Check if the form was submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Validate the amount input
    if (empty(trim($_POST["amount"]))) {
        $amount_err = "يرجى إدخال القيمة.";
    } else {
        $amount = trim($_POST["amount"]);
    }

    // Validate the receipt number input
    if (empty(trim($_POST["receipt"]))) {
        $receipt_err = "يرجى إدخال رقم الإيصال.";
    } else {
        $receipt = trim($_POST["receipt"]);
    }

    // Comment is optional, so no strict validation
    $comment = trim($_POST["comment"]);

    // Check if there are no errors before inserting into the database
    if (empty($amount_err) && empty($receipt_err)) {
        // Prepare an insert statement
        $sql = "INSERT INTO accounting (amount, A_J_id, comment) VALUES (?, ?, ?)";

        if ($stmt = $conn->prepare($sql)) {
            // Bind variables to the prepared statement as parameters
            $stmt->bind_param("dss", $param_amount, $param_receipt, $param_comment);

            // Set the parameters
            $param_amount = $amount;
            $param_receipt = $receipt;
            $param_comment = $comment;

            // Attempt to execute the prepared statement
            if ($stmt->execute()) {
                // Redirect to a success page (or display a success message)
                echo "<script>alert('تم حفظ الإيداع بنجاح'); window.location.href='الحسابات.php';</script>";
            } else {
                echo "حدث خطأ أثناء محاولة حفظ البيانات. حاول مرة أخرى.";
            }

            // Close the statement
            $stmt->close();
        }
    }
}

// Close the connection
$conn->close();
?>

<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تسجيل إيداع</title>
    <style>
        body {
            font-family: 'Cairo', sans-serif;
            margin: 0;
            padding: 0;
            direction: rtl;
        }
        .container {
            max-width: 1000px;
            margin: 20px auto;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        .breadcrumb {
            margin-bottom: 20px;
            font-size: 14px;
            color: #777;
        }
        .breadcrumb a {
            color: #3498db;
            text-decoration: none;
        }
        .breadcrumb a:hover {
            text-decoration: underline;
        }
        h2 {
            font-size: 24px;
            margin-bottom: 20px;
            text-align: right;
        }
        form {
            background-color: #fff;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        label {
            display: block;
            margin-bottom: 10px;
            font-weight: bold;
        }
        input[type="text"], textarea {
            width: calc(100% - 24px);
            padding: 10px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        textarea {
            height: 80px;
        }
        .form-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .form-row > div {
            flex: 1;
            margin-left: 10px;
        }
        .form-row > div:first-child {
            margin-left: 0;
        }
        .actions {
            text-align: right;
        }
        .actions button {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-left: 10px;
        }
        .actions .save-btn {
            background-color: #3498db;
            color: white;
        }
        .actions .cancel-btn {
            background-color: #e74c3c;
            color: white;
        }
        .actions .save-btn:hover {
            background-color: #2980b9;
        }
        .actions .cancel-btn:hover {
            background-color: #c0392b;
        }
        .error {
            color: #e74c3c;
            font-size: 14px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>

<div class="container">
    <!-- Breadcrumb navigation -->
    <div class="breadcrumb">
        <a href="الرئيسية.php">الرئيسية</a> - 
        <a href="الحسابات.php">الحسابات</a> - 
        تسجيل إيداع
    </div>

    <h2>تسجيل إيداع</h2>

    <form action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>" method="POST">
        <!-- First row with the amount and receipt number fields -->
        <div class="form-row">
            <div>
                <label for="amount">القيمة</label>
                <input type="text" id="amount" name="amount" placeholder="أدخل القيمة" value="<?php echo $amount; ?>">
                <span class="error"><?php echo $amount_err; ?></span>
            </div>
            <div>
                <label for="receipt">رقم الإيصال</label>
                <input type="text" id="receipt" name="receipt" placeholder="أدخل رقم الإيصال" value="<?php echo $receipt; ?>">
                <span class="error"><?php echo $receipt_err; ?></span>
            </div>
        </div>

        <!-- Comments field -->
        <label for="comment">تعليق</label>
        <textarea id="comment" name="comment" placeholder="أدخل تعليق"><?php echo $comment; ?></textarea>

        <!-- Action buttons -->
        <div class="actions">
            <button type="submit" class="save-btn">حفظ</button>
            <button type="button" class="cancel-btn" onclick="window.history.back();">تراجع</button>
        </div>
    </form>
</div>

</body>
</html>

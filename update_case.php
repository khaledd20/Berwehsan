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

// Check if the form was submitted
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Validate and sanitize inputs
    $caseId = isset($_POST['id']) && is_numeric($_POST['id']) ? (int)$_POST['id'] : 0;

    $caseName = isset($_POST['case_name']) ? $conn->real_escape_string($_POST['case_name']) : '';
    $mostArea = isset($_POST['most_area']) ? $conn->real_escape_string($_POST['most_area']) : '';
    $mostBox = isset($_POST['most_box']) ? $conn->real_escape_string($_POST['most_box']) : '';
    $familyMembers = isset($_POST['family_members']) ? (int)$_POST['family_members'] : 0;
    $clothesSize = isset($_POST['clothes_size']) ? $conn->real_escape_string($_POST['clothes_size']) : '';
    $phoneNumber = isset($_POST['phone_number']) ? $conn->real_escape_string($_POST['phone_number']) : '';
    $nationalId = isset($_POST['national_id']) ? $conn->real_escape_string($_POST['national_id']) : '';
    $schoolStage = isset($_POST['school_stage']) ? $conn->real_escape_string($_POST['school_stage']) : '';
    $shoeSize = isset($_POST['shoe_size']) ? (int)$_POST['shoe_size'] : 0;
    $socialStatus = isset($_POST['social_status']) ? $conn->real_escape_string($_POST['social_status']) : '';
    $feedingTimes = isset($_POST['feeding_times']) ? (int)$_POST['feeding_times'] : 0;

    // Check if case ID is valid
    if ($caseId > 0) {
        // Prepare the SQL query to update the case
        $stmt = $conn->prepare("
            UPDATE cases 
            SET 
                name = ?, 
                location = ?, 
                chest_id = ?, 
                family_id = ?, 
                c_size = ?, 
                number = ?, 
                ID_Number = ?, 
                source = ?, 
                S_size = ?, 
                social_status = ?, 
                food_times = ?
            WHERE id = ?
        ");
        $stmt->bind_param(
            "sssisisssisi", 
            $caseName, 
            $mostArea, 
            $mostBox, 
            $familyMembers, 
            $clothesSize, 
            $phoneNumber, 
            $nationalId, 
            $schoolStage, 
            $shoeSize, 
            $socialStatus, 
            $feedingTimes, 
            $caseId
        );

        // Execute the query
        if ($stmt->execute()) {
            echo "<div style='color: green; text-align: center;'>Case updated successfully!</div>";
        } else {
            echo "<div style='color: red; text-align: center;'>Error updating case: " . $stmt->error . "</div>";
        }

        $stmt->close(); // Close the statement
    } else {
        echo "<div style='color: red; text-align: center;'>Invalid case ID!</div>";
    }
} else {
    echo "<div style='color: red; text-align: center;'>Invalid request method!</div>";
}

// Close the connection
$conn->close();
?>

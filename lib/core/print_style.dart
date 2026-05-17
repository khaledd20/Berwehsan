import 'package:flutter/material.dart';

class PrintStyle {
  static String get htmlHead => '''
<head>
  <meta charset="UTF-8">
  <style>
    body { 
      direction: rtl; 
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
      margin: 40px; 
      color: #0A2B1D; 
    }
    .header-container { 
      display: flex; 
      justify-content: space-between; 
      align-items: center; 
      margin-bottom: 20px; 
      border-bottom: 3px solid #1B5E37; 
      padding-bottom: 10px; 
    }
    .header-title { 
      color: #1B5E37; 
      margin: 0; 
      font-size: 24px; 
    }
    .header-logo { 
      max-width: 100px; 
      max-height: 100px; 
    }
    table { 
      width: 100%; 
      border-collapse: collapse; 
      margin-top: 20px; 
      font-size: 14px; 
    }
    th, td { 
      border: 1px solid #ddd; 
      padding: 12px; 
      text-align: right; 
    }
    th { 
      background-color: #1B5E37; 
      color: white; 
      font-weight: bold; 
    }
    tr:nth-child(even) { 
      background-color: #f9f9f9; 
    }
    tr:hover {
      background-color: #eaf1eb;
    }
    @media print { 
      body { margin: 0; } 
      .header-container { margin-top: 20px; } 
      table { page-break-inside: auto; }
      tr { page-break-inside: avoid; page-break-after: auto; }
    }
  </style>
</head>
''';

  static String getHeader(String title) {
    // Note: Relative assets might not load in blob URLs in some browsers.
    // If logo is missing, a base64 encoded version is recommended.
    return '''
<div class="header-container">
  <h2 class="header-title">$title</h2>
  <img class="header-logo" src="assets/images/image.png" alt="Logo" onerror="this.style.display='none'">
</div>
''';
  }
}

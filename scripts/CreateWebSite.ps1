# Function to generate the HTML <head> section
function Generate-HTMLHead {
    @"
<!DOCTYPE html>
<html lang='en'>
  <head>
    <meta charset='UTF-8' />
    <meta name='viewport' content='width=device-width, initial-scale=1.0' />
    <title>Review Checklist</title>
    <link rel='stylesheet' href='styles.css' />
    <script src='https://d3js.org/d3.v7.min.js'></script>
    <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
  </head>
"@
}

# Function to generate the header section
function Generate-HTMLHeader {
    @"
<header>
  <h1>Azure Review Checklist</h1>
</header>
"@
}

# Function to generate the main content section
function Generate-MainSection {
    @"
<main>
  <section>
    <div class='container'>
      <div class='section header'>Review Status</div>

      <!-- Large Chart (Overall Status) -->
      <div class='section chart-x-large'>
        <h3>Status (Overall)</h3>
        <table class='styled-table'>
          <thead>
            <tr>
              <th>Severity</th>
              <th>Implemented</th>
              <th>Partial Implemented</th>
              <th>Not Implemented</th>
              <th>Unknown</th>
              <th>Manual Verification Required</th>
              <th>Not Applicable</th>
              <th>Not Developed</th>
              <th>Error</th>
            </tr>
          </thead>
          <tbody id='table-body-overall'></tbody>
        </table>
      </div>

      <div class='section chart-small'>
        <h3>Status (Overall)</h3>
        <canvas id='designAreaPieChart' width='100%' height='100%'></canvas>
      </div>

      <div class='section chart-medium'>
        <h3>Status (Per category)</h3>
        <table class='styled-table'>
          <thead>
            <tr>
              <td>Category</td>
              <td>Not verified</td>
              <td>Open</td>
              <td>Closed</td>
              <td>Total</td>
              <td>Progress</td>
            </tr>
          </thead>
          <tbody id='table-body-category'></tbody>
        </table>
        <canvas id='wafChart' width='100%' height='100%'></canvas>
      </div>

      <div class='section chart-medium'>
        <h3>Overall Checks (Per Design Area)</h3>
        <canvas id='lowRadarChart' width='100%' height='100%'></canvas>
      </div>
      <div class='section chart-xx-large'>
        <h3>Details</h3>
        <table class='fixed-header-table'>
          <tbody id='table-body-all-items'></tbody>
        </table>
      </div>
    </div>
  </section>
</main>
"@
}

# Function to generate the JavaScript section
function Generate-JavaScript {
    @"
<script>
const jsonReportListData =
    __REPORTLISTDATA__
;

const categoryMapping = {
  "Azure Billing and Microsoft Entra ID Tenants": "Billing",
  "Identity and Access Management": "IAM",
  "Network Topology and Connectivity": "Network",
  Security: "Security",
  Management: "Management",
  "Resource Organization": "ResourceOrganization",
  "Platform Automation and DevOps": "DevOps",
  Governance: "Governance",
};

const Status = {
    Implemented: 1,
    PartialImplemented: 2,
    NotImplemented: 3,
    Unknown: 4,
    ManualVerificationRequired: 5,
    NotApplicable: 6,
    Error: 7,
};

function calculateStatusData() {
    const statusCounts = {
        High: {
            Implemented: 0,
            PartialImplemented: 0,
            NotImplemented: 0,
            Unknown: 0,
            ManualVerificationRequired: 0,
            NotApplicable: 0,
            NotDeveloped: 0,
            Error: 0,
        },
        Medium: {
            Implemented: 0,
            PartialImplemented: 0,
            NotImplemented: 0,
            Unknown: 0,
            ManualVerificationRequired: 0,
            NotApplicable: 0,
            NotDeveloped: 0,
            Error: 0,
        },
        Low: {
            Implemented: 0,
            PartialImplemented: 0,
            NotImplemented: 0,
            Unknown: 0,
            ManualVerificationRequired: 0,
            NotApplicable: 0,
            NotDeveloped: 0,
            Error: 0,
        },
        Unknown: {
            Implemented: 0,
            PartialImplemented: 0,
            NotImplemented: 0,
            Unknown: 0,
            ManualVerificationRequired: 0,
            NotApplicable: 0,
            NotDeveloped: 0,
            Error: 0,
        },
    };

    // Iterate through all categories in jsonReportListData
    Object.values(jsonReportListData).forEach((category) => {
        (category || []).forEach((item) => {
            // Access the severity and status directly
            const severity = item.RawSource?.severity || "Unknown";
            const status = item.Status || "Unknown";

            if (!statusCounts[severity]) {
                statusCounts[severity] = {
                    Implemented: 0,
                    PartialImplemented: 0,
                    NotImplemented: 0,
                    Unknown: 0,
                    ManualVerificationRequired: 0,
                    NotApplicable: 0,
                    NotDeveloped: 0,
                    Error: 0,
                };
            }

            // Increment the appropriate status count
            switch (status) {
                case "Implemented":
                    statusCounts[severity].Implemented++;
                    break;
                case "PartialImplemented":
                    statusCounts[severity].PartialImplemented++;
                    break;
                case "NotImplemented":
                    statusCounts[severity].NotImplemented++;
                    break;
                case "Unknown":
                    statusCounts[severity].Unknown++;
                    break;
                case "ManualVerificationRequired":
                    statusCounts[severity].ManualVerificationRequired++;
                    break;
                case "NotApplicable":
                    statusCounts[severity].NotApplicable++;
                    break;
                case "NotDeveloped":
                    statusCounts[severity].NotDeveloped++;
                    break;
                case "Error":
                    statusCounts[severity].Error++;
                    break;
                default:
                    statusCounts[severity].Unknown++;
            }
        });
    });

    return statusCounts;
}

function calculateCategoryStatusData() {
  const categoryStatusCounts = {};

  Object.keys(categoryMapping).forEach((category) => {
    categoryStatusCounts[category] = {
      NotVerified: 0,
      Open: 0,
      Closed: 0,
      Total: 0,
      Progress: 0,
    };
  });

  Object.entries(jsonReportListData).forEach(([categoryKey, items]) => {
    const categoryName = Object.keys(categoryMapping).find(
      (key) => categoryMapping[key] === categoryKey
    );
    if (categoryName) {
      items.forEach((item) => {
        switch (item.Status) {
          case Status.Implemented:
            categoryStatusCounts[categoryName].Closed++;
            break;
          case Status.PartialImplemented:
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case Status.NotImplemented:
            categoryStatusCounts[categoryName].Open++;
            break;
          case Status.Unknown:
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case Status.ManualVerificationRequired:
            categoryStatusCounts[categoryName].Open++;
            break;
          case Status.NotApplicable:
            categoryStatusCounts[categoryName].Closed++;
            break;
          case Status.NotDeveloped:
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case Status.Error:
            categoryStatusCounts[categoryName].Open++;
            break;
          default:
            categoryStatusCounts[categoryName].NotVerified++;
        }
      });

      // Calculate Total and Progress
      const total =
        categoryStatusCounts[categoryName].NotVerified +
        categoryStatusCounts[categoryName].Open +
        categoryStatusCounts[categoryName].Closed;
      categoryStatusCounts[categoryName].Total = total;
      categoryStatusCounts[categoryName].Progress =
        total > 0
          ? (categoryStatusCounts[categoryName].Closed / total) * 100
          : 0;
    }
  });

  return categoryStatusCounts;
}
  
function populateCategoryTable() {
  const tableBody = document.getElementById("table-body-category");
  const categoryStatusData = calculateCategoryStatusData();

  Object.keys(categoryStatusData).forEach((category) => {
    const row = categoryStatusData[category];
    const tr = document.createElement("tr");
    tr.innerHTML = `
  "<td>" + category + "</td>" +
  "<td>" + row.NotVerified + "</td>" +
  "<td>" + row.Open + "</td>" +
  "<td>" + row.Closed + "</td>" +
  "<td>" + row.Total + "</td>" +
  "<td>" + row.Progress.toFixed(2) + "%</td>";
    tableBody.appendChild(tr);
  });
  // Update the radar chart with the category data
  updateRadarChart(categoryStatusData);
}

function populateTable() {
  const tableBody = document.getElementById("table-body-overall");
  const statusData = calculateStatusData();

  let totalImplemented = 0;
  let totalPartialImplemented = 0;
  let totalNotImplemented = 0;
  let totalUnknown = 0;
  let totalManualVerificationRequired = 0;
  let totalNotApplicable = 0;
  let totalNotDeveloped = 0;
  let totalError = 0;

  Object.keys(statusData).forEach((severity) => {
    const row = statusData[severity];
    totalImplemented += row.Implemented;
    totalPartialImplemented += row.PartialImplemented;
    totalNotImplemented += row.NotImplemented;
    totalUnknown += row.Unknown;
    totalManualVerificationRequired += row.ManualVerificationRequired;
    totalNotApplicable += row.NotApplicable;
    totalNotDeveloped += row.NotDeveloped;
    totalError += row.Error;

    const tr = document.createElement("tr");
    tr.innerHTML = `
 "<td>" + severity + "</td>" +
  "<td>" + row.Implemented + "</td>" +
  "<td>" + row.PartialImplemented + "</td>" +
  "<td>" + row.NotImplemented + "</td>" +
  "<td>" + row.Unknown + "</td>" +
  "<td>" + row.ManualVerificationRequired + "</td>" +
  "<td>" + row.NotApplicable + "</td>" +
  "<td>" + row.NotDeveloped + "</td>" +
  "<td>" + row.Error + "</td>";
    tableBody.appendChild(tr);
  });

  // Add total row
  const totalRow = document.createElement("tr");
  totalRow.innerHTML = `
 "<td><strong>Total</strong></td>" +
  "<td><strong>" + totalImplemented + "</strong></td>" +
  "<td><strong>" + totalPartialImplemented + "</strong></td>" +
  "<td><strong>" + totalNotImplemented + "</strong></td>" +
  "<td><strong>" + totalUnknown + "</strong></td>" +
  "<td><strong>" + totalManualVerificationRequired + "</strong></td>" +
  "<td><strong>" + totalNotApplicable + "</strong></td>" +
  "<td><strong>" + totalNotDeveloped + "</strong></td>" +
  "<td><strong>" + totalError + "</strong></td>";
  tableBody.appendChild(totalRow);

  // Update the pie chart with the totals
  updatePieChart({
    Implemented: totalImplemented,
    PartialImplemented: totalPartialImplemented,
    NotImplemented: totalNotImplemented,
    Unknown: totalUnknown,
    ManualVerificationRequired: totalManualVerificationRequired,
    NotApplicable: totalNotApplicable,
    NotDeveloped: totalNotDeveloped,
    Error: totalError,
  });

  // Populate the category table
  populateCategoryTable();
}

function updatePieChart(totals) {
  const ctxDesignAreaPie = document
    .getElementById("designAreaPieChart")
    .getContext("2d");
  const designAreaPieChart = new Chart(ctxDesignAreaPie, {
    type: "pie",
    data: {
      labels: [
        "Implemented",
        "Partial Implemented",
        "Not Implemented",
        "Unknown",
        "Manual Verification Required",
        "Not Applicable",
        "Not Developed",
        "Error",
      ],
      datasets: [
        {
          label: "Overall Status",
          data: [
            totals.Implemented,
            totals.PartialImplemented,
            totals.NotImplemented,
            totals.Unknown,
            totals.ManualVerificationRequired,
            totals.NotApplicable,
            totals.NotDeveloped,
            totals.Error,
          ],
          backgroundColor: [
            "rgba(75, 192, 192, 0.2)",
            "rgba(54, 162, 235, 0.2)",
            "rgba(255, 99, 132, 0.2)",
            "rgba(255, 206, 86, 0.2)",
            "rgba(153, 102, 255, 0.2)",
            "rgba(255, 159, 64, 0.2)",
            "rgba(255, 159, 108, 0.2)",
            "rgba(201, 203, 207, 0.2)",
          ],
          borderColor: [
            "rgba(75, 192, 192, 1)",
            "rgba(54, 162, 235, 1)",
            "rgba(255, 99, 132, 1)",
            "rgba(255, 206, 86, 1)",
            "rgba(153, 102, 255, 1)",
            "rgba(255, 159, 64, 1)",
            "rgba(255, 159, 108, 1)",
            "rgba(201, 203, 207, 1)",
          ],
          borderWidth: 1,
        },
      ],
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: "top",
        },
        title: {
          display: true,
          text: "Overall Status Pie Chart",
        },
      },
    },
  });
}

function updateRadarChart(categoryStatusData) {
  const labels = Object.keys(categoryStatusData);
  const data = labels.map(
    (category) => categoryStatusData[category].Progress
  );

  const ctxLowRadar = document
    .getElementById("lowRadarChart")
    .getContext("2d");
  const lowRadarChart = new Chart(ctxLowRadar, {
    type: "radar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Progress",
          data: data,
          backgroundColor: "rgba(54, 162, 235, 0.2)",
          borderColor: "rgba(54, 162, 235, 1)",
          borderWidth: 1,
        },
      ],
    },
    options: {
      responsive: true,
      plugins: {
        title: {
          display: true,
          text: "Progress by Category",
        },
      },
      scales: {
        r: {
          angleLines: {
            display: true,
          },
          suggestedMin: 0,
          suggestedMax: 100,
        },
      },
    },
  });
}


function calculateWAFData() {
  const wafCounts = {};

  Object.values(jsonReportListData).forEach((category) => {
      (category || []).forEach((item) => {
          const waf = item.RawSource?.waf || "Unknown";
          if (!wafCounts[waf]) {
            wafCounts[waf] = 0;
          }
          const reportItem = Object.values(jsonReportListData)
            .flat()
            .find((report) => report.RawSource?.id === item.RawSource?.id);
          if (reportItem) {
            wafCounts[waf]++;
          }
      });
  });

  return wafCounts;
}

function updateWAFChart() {
  const wafData = calculateWAFData();
  const labels = Object.keys(wafData);
  const data = Object.values(wafData);

  const ctxWAFChart = document
    .getElementById("wafChart")
    .getContext("2d");
  const wafChart = new Chart(ctxWAFChart, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "WAF Indicator",
          data: data,
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          borderColor: "rgba(75, 192, 192, 1)",
          borderWidth: 1,
        },
      ],
    },
    options: {
      responsive: true,
      plugins: {
        legend: {
          position: "top",
        },
        title: {
          display: true,
          text: "WAF Indicator Chart",
        },
      },
      scales: {
        y: {
          beginAtZero: true,
        },
      },
    },
  });
}

function getCoveredItems() {
  const coveredItems = [];

  // Iterate over each category in jsonReportListData
  Object.values(jsonReportListData).forEach((category) => {
    // Ensure the category is an array and iterate over its items
    (category || []).forEach((checkItem) => {
      const categoryKey = Object.keys(categoryMapping).find((key) => {
        console.log(
          "Comparing: " +
            categoryMapping[key] +
            " with " +
            (checkItem.RawSource ? checkItem.RawSource.category : "undefined")
        );
        return key === checkItem.RawSource?.category;
      });

      if (categoryKey) {
        const reportItems =
          jsonReportListData[categoryMapping[categoryKey]] || [];
        const matchedItem = reportItems.find(
          (reportItem) =>
            reportItem.RawSource?.id === checkItem.RawSource?.id &&
            reportItem.Status === Status.Implemented
        );

        // Add matched or unmatched items to coveredItems
        coveredItems.push({
          category: categoryKey,
          subcategory: checkItem.RawSource?.subcategory,
          status: matchedItem
            ? Object.keys(Status).find(
                (key) => Status[key] === matchedItem.Status
              )
            : "Open",
          description: checkItem.RawSource?.text,
          waf: checkItem.RawSource?.waf,
          service: checkItem.RawSource?.service,
          id: checkItem.RawSource?.id,
          severity: checkItem.RawSource?.severity,
          training: checkItem.RawSource?.training,
          reference: checkItem.RawSource?.link,
        });
      }
    });
  });

  return coveredItems;
}


function populateAllItemsTable() {
  const tableBody = document.getElementById("table-body-all-items");
  const coveredItems = getCoveredItems();
  const categories = [
    ...new Set(coveredItems.map((item) => item.category)),
  ];

  categories.forEach((category) => {
    const headerRow = document.createElement("tr");
    const headerCell = document.createElement("td");
    headerCell.colSpan = 10;
    headerCell.className = "collapsible";
    headerCell.innerText = category;
    headerCell.onclick = function () {
      this.classList.toggle("active");
      const content = this.parentElement.nextElementSibling;
      if (content && content.classList.contains("content")) {
        if (content.style.display === "table-row-group") {
          content.style.display = "none";
        } else {
          content.style.display = "table-row-group";
        }
      }
    };
    headerRow.appendChild(headerCell);
    tableBody.appendChild(headerRow);

    const contentRowGroup = document.createElement("tbody");
    contentRowGroup.className = "content";

    const contentHeaderRow = document.createElement("tr");
    const headers = [
      "Category",
      "Subcategory",
      "Status",
      "Description",
      "WAF Category",
      "Service",
      "id",
      "Severity",
      "Training",
      "Reference",
    ];
    headers.forEach((headerText) => {
      const th = document.createElement("th");
      th.innerText = headerText;
      contentHeaderRow.appendChild(th);
    });
    contentRowGroup.appendChild(contentHeaderRow);

    coveredItems
      .filter((item) => item.category === category)
      .forEach((item) => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
  "<td>" + item.category + "</td>" +
  "<td>" + item.subcategory + "</td>" +
  "<td>" + item.status + "</td>" +
  "<td>" + item.description + "</td>" +
  "<td>" + item.waf + "</td>" +
  "<td>" + item.service + "</td>" +
  "<td>" + item.id + "</td>" +
  "<td>" + item.severity + "</td>" +
  "<td><a href='" + item.training + "'>Training</a></td>" +
  "<td><a href='" + item.reference + "'>Reference</a></td>";
        contentRowGroup.appendChild(tr);
      });

    tableBody.appendChild(contentRowGroup);
  });
}

 window.onload = function () {
  populateTable();
  updateWAFChart();
  populateAllItemsTable();
};
</script>
"@
}

# Function to generate the HTML footer
function Generate-HTMLFooter {
    @"
  </body>
</html>
"@
}

# Function to generate the complete HTML
function Generate-HTML {
    $html = @()
    $html += Generate-HTMLHead
    $html += "<body>"
    $html += Generate-HTMLHeader
    $html += Generate-MainSection
    $html += Generate-JavaScript
    $html += Generate-HTMLFooter
    $html -join "`n"
}

# Replace the placeholder __REPORTLISTDATA__ with content from the JSON file
function Replace-ReportDataPlaceholder {
    param (
        [string]$HTMLContent,
        [string]$ReportJsonPath
    )

    # Read the JSON file
    $reportJsonContent = Get-Content -Path $ReportJsonPath -Raw
    # Replace the placeholder with the JSON content
    return $HTMLContent -replace "__REPORTLISTDATA__", $reportJsonContent
}

# Define the path to the report.json file
$reportJsonPath = "$PSScriptRoot/../reports/report.json"

# Generate the HTML and replace the placeholder
$htmlContent = Generate-HTML
$htmlContent = Replace-ReportDataPlaceholder -HTMLContent $htmlContent -ReportJsonPath $reportJsonPath

# Save the final HTML to a file
$outputPath = "$PSScriptRoot/../web/index.html"
Set-Content -Path $outputPath -Value $htmlContent -Encoding UTF8

Write-Output "HTML generated at: $outputPath"

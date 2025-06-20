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

function Generate-HTMLHeader {
  @"
<header>
  <h1>Azure Review Checklist</h1>
</header>
"@
}

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
      <div class="section chart-xx-large">
        <h3>Error Log</h3>
        <table class='fixed-header-table'>
          <tbody id='table-body-error-items'></tbody>
        </table>
      </div>
      <div class="section chart-xx-large">
        <h3>Exceptions</h3>
        <table class='fixed-header-table'>
          <tbody id='table-body-exceptions'></tbody>
        </table>
      </div>
    </div>
  </section>
</main>
"@
}

function Generate-JavaScript {
  $js = @()
  $js += Generate-JavaScriptConstants
  $js += Generate-JavaScriptInitialization
  $js += Generate-JavaScriptFunctions
  $js -join "`n"
}

function Generate-JavaScriptConstants {
  @"
const jsonReportListData = __REPORTLISTDATA__;
const errorLogData = __ERRORLOGDATA__;
const exceptionsData = __EXCEPTIONSDATA__;

const categoryMapping = {
"Azure Billing and Microsoft Entra ID Tenants": "Billing",
"Identity and Access Management": "IAM",
"Network Topology and Connectivity": "Network",
"Security": "Security",
"Management": "Management",
"Resource Organization": "ResourceOrganization",
"Platform Automation and DevOps": "DevOps",
"Governance": "Governance",
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
"@
}

function Generate-JavaScriptInitialization {
  @"
window.onload = function () {
  populateOverallStatusTable();
  updateWAFChart();
  populateDetailsTable();
  populateErrorLogTable();
  populateExceptionsTable();
};
"@
}

function Generate-JavaScriptFunctions {
  $functions = @()
  $functions += GenerateCalculateStatusDataFunction
  $functions += GenerateCalculateCategoryStatusDataFunction
  $functions += GeneratePopulateOverallStatusTableFunction
  $functions += GeneratePopulateCategoryTableFunction
  $functions += GeneratePopulateDetailsTableFunction
  $functions += GeneratePopulateErrorLogTableFunction
  $functions += GeneratePopulateExceptionsTableFunction
  $functions += GeneratePieChartFunction
  $functions += GenerateRadarChartFunction
  $functions += GenerateWAFChartFunction
  $functions -join "`n"
}

function GenerateCalculateStatusDataFunction {
  @"
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
"@
}

function GenerateCalculateCategoryStatusDataFunction {
  @"
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
          case "Implemented":
            categoryStatusCounts[categoryName].Closed++;
            break;
          case "PartialImplemented":
            categoryStatusCounts[categoryName].Open++;
            break;
          case "NotImplemented":
            categoryStatusCounts[categoryName].Open++;
            break;
          case "Unknown":
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case "ManualVerificationRequired":
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case "NotApplicable":
            categoryStatusCounts[categoryName].Closed++;
            break;
          case "NotDeveloped":
            categoryStatusCounts[categoryName].NotVerified++;
            break;
          case "Error":
            categoryStatusCounts[categoryName].NotVerified++;
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
"@
}

function GeneratePopulateOverallStatusTableFunction {
  @"
function populateOverallStatusTable() {
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
  populatePieChart({
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
"@
}

function GeneratePopulateCategoryTableFunction {
  @"
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
  populateRadarChart(categoryStatusData);
}
"@
}

function GeneratePopulateDetailsTableFunction {
  @"
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
          status: checkItem.Status,
          description: checkItem.RawSource?.text,
          waf: checkItem.RawSource?.waf,
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

function populateDetailsTable() {
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
  "<td>" + item.id + "</td>" +
  "<td>" + item.severity + "</td>" +
  "<td><a href='" + item.training + "'>Training</a></td>" +
  "<td><a href='" + item.reference + "'>Reference</a></td>";
        contentRowGroup.appendChild(tr);
      });

    tableBody.appendChild(contentRowGroup);
  });
}
"@
}

function GeneratePopulateErrorLogTableFunction {
  @"
function populateErrorLogTable() {
    const errorLogContainer = document.getElementById('table-body-error-items');
    errorLogContainer.innerHTML = ''; // Clear previous content

    const categories = [...new Set(errorLogData.errorsArray.map(error => error.Category))];

    categories.forEach(category => {
        // Create collapsible header
        const headerRowE = document.createElement("tr");
        const headerCellE = document.createElement("td");
        headerCellE.colSpan = 10;
        headerCellE.className = 'collapsible';
        headerCellE.innerText = category;
        headerCellE.onclick = function () {
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
        headerRowE.appendChild(headerCellE);
        errorLogContainer.appendChild(headerRowE);

        const contentRowGroupE = document.createElement("tbody");
        contentRowGroupE.className = "content";

        const contentHeaderRowE = document.createElement("tr");
        const headersE = [
          "Question ID",
          "Question Text",
          "Error Message",
        ];
        headersE.forEach((headerText) => {
          const th = document.createElement("th");
          th.innerText = headerText;
          contentHeaderRowE.appendChild(th);
        });
        contentRowGroupE.appendChild(contentHeaderRowE);



        errorLogData.errorsArray
                .filter(error => error.Category === category)
                .forEach(error => {
                  const tr = document.createElement("tr");
                  tr.innerHTML = `
                        "<td>" + error.QuestionID + "</td>" +
                        "<td>" + error.QuestionText + "</td>" +
                        "<td>" + error.ErrorMessage + "</td>";
                  contentRowGroupE.appendChild(tr);
        });
        errorLogContainer.appendChild(contentRowGroupE);
    });
}
"@
}

function GeneratePopulateExceptionsTableFunction {
  @"
function populateExceptionsTable() {
    const exceptionsContainer = document.getElementById('table-body-exceptions');
    exceptionsContainer.innerHTML = ''; // Clear previous content

    const categories = [...new Set(exceptionsData.exceptions.map(exception => exception.Category))];

    categories.forEach(category => {
        // Create collapsible header
        const headerRowX = document.createElement("tr");
        const headerCellX = document.createElement("td");
        headerCellX.colSpan = 10;
        headerCellX.className = 'collapsible';
        headerCellX.innerText = category;
        headerCellX.onclick = function () {
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
        headerRowX.appendChild(headerCellX);
        exceptionsContainer.appendChild(headerRowX);

        const contentRowGroupX = document.createElement("tbody");
        contentRowGroupX.className = "content";

        const contentHeaderRowX = document.createElement("tr");
        const headersX = [
          "Question ID",
          "Question Text",
          "Status Report",
          "New Status",
        ];
        headersX.forEach((headerText) => {
          const th = document.createElement("th");
          th.innerText = headerText;
          contentHeaderRowX.appendChild(th);
        });
        contentRowGroupX.appendChild(contentHeaderRowX);



        exceptionsData.exceptions
                .filter(exception => exception.Category === category)
                .forEach(exception => {
                  const tr = document.createElement("tr");
                  tr.innerHTML = `
                        "<td>" + exception.QuestionID + "</td>" +
                        "<td>" + exception.QuestionText + "</td>" +
                        "<td>" + exception.StatusReport + "</td>" +
                        "<td>" + exception.NewStatus + "</td>";
                  contentRowGroupX.appendChild(tr);
        });
        exceptionsContainer.appendChild(contentRowGroupX);
    });
}
"@
}

function GeneratePieChartFunction {
  @"
function populatePieChart(totals) {
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
"@
}

function GenerateRadarChartFunction {
  @"
function populateRadarChart(categoryStatusData) {
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
"@
}
function GenerateWAFChartFunction {
  @"
  function calculateWAFData() {
    const wafCounts = {};

    Object.values(jsonReportListData).forEach((category) => {
        (category || []).forEach((item) => {
            const waf = item.RawSource?.waf || "Unknown";
            if (!wafCounts[waf]) {
                wafCounts[waf] = 0;
            }
            wafCounts[waf]++;
        });
    });

    return wafCounts;
}

function updateWAFChart() {
  const wafData = calculateWAFData();
  const labels = Object.keys(wafData);
  const data = Object.values(wafData);

  const ctx = document.getElementById('wafChart').getContext('2d');
  new Chart(ctx, {
      type: 'bar',
      data: {
          labels: labels,
          datasets: [
              {
                  label: 'WAF Indicator',
                  data: data,
                  backgroundColor: 'rgba(75, 192, 192, 0.2)',
                  borderColor: 'rgba(75, 192, 192, 1)',
                  borderWidth: 1,
              },
          ],
      },
      options: {
          responsive: true,
          plugins: {
              legend: {
                  position: 'top',
              },
              title: {
                  display: true,
                  text: 'WAF Indicator Chart',
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
"@
}
function Generate-HTMLFooter {
  @"
  </body>
</html>
"@
}

function Generate-HTML {
  $html = @()
  $html += Generate-HTMLHead
  $html += "<body>"
  $html += Generate-HTMLHeader
  $html += Generate-MainSection
  $html += "<script>"
  $html += Generate-JavaScript
  $html += "</script>"
  $html += Generate-HTMLFooter
  $html -join "`n"
}

function Replace-ReportDataPlaceholder {
  param (
      [string]$HTMLContent,
      [string]$ReportJsonPath,
      [string]$ExceptionsJsonPath
  )

  # Apply exceptions and get updated report content
  $result = Apply-ExceptionsToReport -ReportJsonPath $ReportJsonPath -ExceptionsJsonPath $ExceptionsJsonPath

  $alteredReportJson = $result.ReportData
  $exceptionsApplied = $result.ExceptionsApplied | ConvertTo-Json -Depth 15

  # Replace the placeholder with updated report JSON
  $updatedHTMLContent = $HTMLContent -replace "__REPORTLISTDATA__", $alteredReportJson

  # Add exceptions data to the HTML
  return $updatedHTMLContent -replace "__EXCEPTIONSDATA__", $exceptionsApplied
}

function Replace-ErrorLogDataPlaceholder {
  param (
      [string]$HTMLContent,
      [string]$ErrorLogPath
  )

  # Read the ErrorLog.json file
  if (Test-Path -Path $ErrorLogPath) {
      $jsonContent = Get-Content -Path $ErrorLogPath -Raw

      # Escape JSON for embedding in JavaScript
      $escapedJsonContent = $jsonContent -replace '"', '\"' -replace "`r?`n", ""

      # Replace the placeholder with the escaped JSON content
      return $HTMLContent -replace "__ERRORLOGDATA__", $jsonContent
  } else {
      Write-Warning "Error log file not found at $ErrorLogPath - using empty error log"
      # Return HTML with empty error log data
      $emptyErrorLog = '{"errorsArray": []}'
      return $HTMLContent -replace "__ERRORLOGDATA__", $emptyErrorLog
  }
}

function Apply-ExceptionsToReport {
  param (
      [string]$ReportJsonPath,
      [string]$ExceptionsJsonPath
  )

  $reportData = @{ }
  if (Test-Path -Path $ReportJsonPath) {
      $reportData = Get-Content -Path $ReportJsonPath | ConvertFrom-Json
  } else {
      Write-Warning "Report file not found at $ReportJsonPath"
      return @{
          ReportData         = "{}"
          ExceptionsApplied  = @{ exceptions = @() }
      }
  }

  $exceptionsData = @{ exceptions = @() }
  if (Test-Path -Path $ExceptionsJsonPath) {
      $exceptionsData = Get-Content -Path $ExceptionsJsonPath | ConvertFrom-Json
  } else {
      Write-Warning "Exceptions file not found at $ExceptionsJsonPath - proceeding without exceptions"
  }

  $categories = @('Billing', 'IAM', 'ResourceOrganization', 'Network', 'Governance', 'Security', 'DevOps', 'Management')
  $exceptionsApplied = @()

  foreach ($category in $categories) {
      if ($reportData.$category -is [System.Collections.IEnumerable]) {
          foreach ($item in $reportData.$category) {
              $exception = $exceptionsData.exceptions | Where-Object { $_.id -eq $item.RawSource.id }
              if ($exception) {
                  if ($exception.newStatus -ne $item.Status) {
                      $exceptionsApplied += [PSCustomObject]@{
                          Category         = $item.RawSource.category  
                          QuestionID       = $item.RawSource.id
                          QuestionText     = $item.RawSource.text
                          StatusReport     = $item.Status
                          NewStatus        = $exception.status
                      }

                      # Update the status in the report
                      $item.Status = $exception.newStatus
                      Write-Output "Exception applied for $($item.RawSource.id) in category $category"
                  }

                  # Update the status in exceptions for tracking
                  $exception.status = $item.Status
              }
          }
      }
  }

  return @{
      ReportData         = $reportData | ConvertTo-Json -Depth 15
      ExceptionsApplied  = @{ exceptions = $exceptionsApplied }
  }
}

# Main Code

$errorLogPath = "$PSScriptRoot/../reports/ErrorLog.json"
$reportJsonPath = "$PSScriptRoot/../reports/report.json"
$reportJsonPath = "$PSScriptRoot/../reports/report.json"
$exceptionsJsonPath = "$PSScriptRoot/../shared/exceptions.json"

# Apply exceptions to the report
$result = Apply-ExceptionsToReport -ReportJsonPath $ReportJsonPath -ExceptionsJsonPath $ExceptionsJsonPath
$alteredReportJson = $result.ReportData
$exceptionsApplied = $result.ExceptionsApplied | ConvertTo-Json -Depth 15

# Generate the HTML and replace the placeholder
$htmlContent = Generate-HTML
$htmlContent = Replace-ReportDataPlaceholder -HTMLContent $htmlContent -ReportJsonPath $reportJsonPath -ExceptionsJsonPath $exceptionsJsonPath
$htmlContent = Replace-ErrorLogDataPlaceholder -HTMLContent $htmlContent -ErrorLogPath $errorLogPath

# Save the final HTML to a file
$outputPath = "$PSScriptRoot/../web/index.html"
Set-Content -Path $outputPath -Value $htmlContent -Encoding UTF8

Write-Output "HTML generated at: $outputPath"

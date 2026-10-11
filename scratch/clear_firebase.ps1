$apiKey = "AIzaSyCvgrHhpaPUqlcG6j87cUar__0G5-3aAj0"
$baseUri = "https://firestore.googleapis.com/v1/projects/gdrm-userbase/databases/(default)/documents"

$collections = @("gdrm_users", "gdrm_phones", "gdrm_piracy_alerts", "gdrm_snail_trails")

function Delete-CollectionDocs($collName) {
    Write-Host "`n--- Cleaning collection: ${collName} ---" -ForegroundColor Cyan
    $listUri = "$baseUri/$collName`?pageSize=300&key=$apiKey"
    
    try {
        $res = Invoke-RestMethod -Uri $listUri -Method Get
        if ($res.documents) {
            Write-Host "Found $($res.documents.Count) documents in ${collName}" -ForegroundColor Yellow
            foreach ($doc in $res.documents) {
                $docName = $doc.name
                
                # Check for snail trail subcollections
                if ($collName -eq "gdrm_snail_trails") {
                    $subUri = "https://firestore.googleapis.com/v1/$docName/events?pageSize=300&key=$apiKey"
                    try {
                        $subRes = Invoke-RestMethod -Uri $subUri -Method Get
                        if ($subRes.documents) {
                            foreach ($subDoc in $subRes.documents) {
                                $delSubUri = "https://firestore.googleapis.com/v1/$($subDoc.name)?key=$apiKey"
                                Invoke-RestMethod -Uri $delSubUri -Method Delete
                                Write-Host "  Deleted sub-event: $($subDoc.name)" -ForegroundColor DarkGray
                            }
                        }
                    } catch {
                        # No subcollection or error
                    }
                }
                
                $delUri = "https://firestore.googleapis.com/v1/$docName`?key=$apiKey"
                Invoke-RestMethod -Uri $delUri -Method Delete
                Write-Host "  Deleted: $docName" -ForegroundColor Green
            }
        } else {
            Write-Host "No documents found in ${collName} (already empty)" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error accessing ${collName}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

foreach ($c in $collections) {
    Delete-CollectionDocs $c
}

Write-Host "`nAll Firestore collections have been completely cleared!" -ForegroundColor Green

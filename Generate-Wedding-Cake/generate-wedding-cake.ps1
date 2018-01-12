Function New-Cylinder {
    <#
      .SYNOPSIS Generate right circular cylinder .obj, with optional "rose pedals" detail

      .PARAMETER FilePath Path to existing .obj file
      .PARAMETER N Number of vertices used to approximate the circular base
      .PARAMETER R Radius of the base
      .PARAMETER H Height between the bases
      .PARAMETER Y Starting height y for the lower base (OPTIONAL)
      .PARAMETER P Number of "rose pedals" to add to the base (OPTIONAL)
      .PARAMETER UseShading Whether to include vertex normals for shading (OPTIONAL FLAG)
    #>

    Param (
        [String]$FilePath, [Int]$N, $R, $H, $Y = 0, $P = 0, [Switch]$UseShading
    )

    ### Vertices ###

    1..($N) | ForEach {
        $A = $_ / $N * [Math]::Pi * 2 # Cumulative angle in radians, from 0 -> 2Pi
        If ($P -Ne 0) {
            $S = [Math]::Abs([Math]::Sin($A * $P/2)); # Sinusoid for pedals, add to radius
        }
        Else {
            $S = 0
        }
        $X = [Math]::Round([Math]::Cos($A) * ($R + $S), 3)
        $Z = [Math]::Round([Math]::Sin($A) * ($R + $S), 3)
        "v $X $Y $Z" | Add-Content $FilePath # Lower ring vertices
        "v $X $($Y + $H) $Z" | Add-Content $FilePath # Upper ring vertices
        If ($UseShading) {
            # Radial outward
            "vn $X 0 $Z" | Add-Content $FilePath
            "vn $X 0 $Z" | Add-Content $FilePath # Duplicative to simplify indexing
        }
    }

    ### Cylinder side walls ###

    (-2 * $N)..-3 | ForEach {
        If ($_ % 2 -Eq 0) { # Generalize from 1 -> 2 -> 4 -> 3 base case, even (reverse-)indices only
            $v1 = $_
            $v2 = $_ + 1
            $v3 = $_ + 3
            $v4 = $_ + 2
            If ($UseShading) {
                "f $v1//$v1 $v2//$v2 $v3//$v3 $v4//$v4" | Add-Content $FilePath
            }
            Else {
                "f $v1 $v2 $v3 $v4" | Add-Content $FilePath
            }
        }
    }

    # Last side wall wraps around to close it
    If ($UseShading) {
        "f -2//-2 -1//-1 $(-2 * $N + 1)//$(-2 * $N + 1) $(-2 * $N)//$(-2 * $N)" | Add-Content $FilePath
    }
    Else {
        "f -2 -1 $(-2 * $N + 1) $(-2 * $N)" | Add-Content $FilePath
    }

    ### Cylinder bases ###

    If ($UseShading) {
        # Straight "up" and "down" vectors for bases
        "vn 0 1 0" | Add-Content $FilePath
        "vn 0 -1 0" | Add-Content $FilePath
    }

    $UpperBase = ""
    $LowerBase = ""
    (-2 * $N)..-1 | ForEach {
        If ($_ % 2 -Eq 0) { # Even (reverse-)indices are lower ring
            If ($UseShading) {
                $LowerBase = $LowerBase + "$_//-1 "
            }
            Else {
                $LowerBase = $LowerBase + "$_ "
            }
        }
        Else { # Odd (reverse-)indices are upper ring
            If ($UseShading) {
                $UpperBase = "$_//-2 " + $UpperBase
            }
            Else {
                $UpperBase = "$_ " + $UpperBase
            }
        }
    }
    "f $UpperBase" | Add-Content $FilePath
    "f $LowerBase" | Add-Content $FilePath
}

$FilePath = "wedding-cake.obj"

"# Wedding cake, generated in PowerShell, by @cosmosdarwin on GitHub/Twitter, Jan 2018" | Out-File -FilePath $FilePath -Encoding ascii

"mtllib wedding-cake-materials.mtl" | Add-Content $FilePath

# Cake foundation
"usemtl white" | Add-Content $FilePath
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 40 -h 20 -y 4
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 30 -h 20 -y 28
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 20 -h 20 -y 52

# Cake accents
"usemtl pink" | Add-Content $FilePath
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 41 -h 4
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 31 -h 4 -y 24
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 21 -h 4 -y 48

# Cake pedals
"usemtl white" | Add-Content $FilePath
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 35 -h 1 -y 24 -p 15
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 25 -h 1 -y 48 -p 15
New-Cylinder -FilePath $FilePath -n 60 -UseShading -r 15 -h 1 -y 72 -p 15
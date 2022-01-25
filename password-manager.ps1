Add-Type -AssemblyName PresentationFramework

# ---------------------------------------------------------------------------
# --------------------- Setting up password collection. ---------------------
# ---------------------------------------------------------------------------

[xml] $passwords = @"
<Sites>
	<!-- Put Your passwords below. -->
	<Site Link="https://online.store.com" Login="user1@yahoo.com" Password="Password1234" />
	<Site Link="https://mymail.com" Login="user2@mymail.com" Password="Pass3256" />
	<!-- Put Your passwords above. -->
</Sites>
"@

class Site {
	[string]$Link
    [string]$Login
    [string]$Password
	
	Site([string]$Link, [string]$Login, [string]$Password) {
        $this.Link = $Link
        $this.Login = $Login
		$this.Password = $Password
    }
}

$sites = New-Object System.Collections.ObjectModel.ObservableCollection[Site]
foreach ($siteNode in $passwords.SelectNodes("//Sites/Site"))
{
	$link = $siteNode.Attributes.GetNamedItem("Link").Value
	$login = $siteNode.Attributes.GetNamedItem("Login").Value
	$password = $siteNode.Attributes.GetNamedItem("Password").Value
	
	$site = [Site]::new($link, $login, $password)
	$sites.Add($site)
}

# ---------------------------------------------------------------------------
# ------------------------- Setting up main window. -------------------------
# ---------------------------------------------------------------------------

[xml] $mainWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Passwords" Height="450" Width="800" 
		WindowStartupLocation="CenterScreen"
		SizeToContent="Width"
		Topmost="True">
    <Grid>
        <Grid.Resources>
            <SolidColorBrush x:Key="GridLinesBrush" Color="LightGray" Opacity=".3" />

            <ContextMenu x:Key="ContextMenu">
                <MenuItem Header="Kopiuj" Command="ApplicationCommands.Copy"/>
            </ContextMenu>
        </Grid.Resources>

        <DataGrid x:Name="Grid"
                  HorizontalGridLinesBrush="{StaticResource GridLinesBrush}"
                  VerticalGridLinesBrush="{StaticResource GridLinesBrush}"
                  CanUserAddRows="False"
                  CanUserDeleteRows="False"
                  CanUserResizeRows="False"
                  CanUserReorderColumns="True"
                  CanUserResizeColumns="True"
                  CanUserSortColumns="True"
				  ContextMenu="{StaticResource ContextMenu}"
                  AutoGenerateColumns="False"
                  SelectionMode="Extended"
                  SelectionUnit="Cell"
                  HorizontalAlignment="Stretch"
                  VerticalAlignment="Stretch"
                  HeadersVisibility="Column"
                  EnableRowVirtualization="True"
                  EnableColumnVirtualization="True"
                  VirtualizingStackPanel.IsVirtualizing="True"
                  VirtualizingStackPanel.VirtualizationMode="Recycling"
                  VirtualizingStackPanel.ScrollUnit="Pixel"
                  UseLayoutRounding="True">

            <DataGrid.CellStyle>
                <Style TargetType="DataGridCell">
                    <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
                    <Setter Property="TextBlock.TextAlignment" Value="Left"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="DataGridCell">
                                <Grid Background="{TemplateBinding Background}">
                                    <ContentPresenter VerticalAlignment="Center"/>
                                </Grid>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </DataGrid.CellStyle>

            <DataGrid.RowStyle>
                <Style TargetType="DataGridRow">
                    <Style.Resources>
                        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="LightGray" Opacity=".4"/>
                        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="Black" />
                    </Style.Resources>
                    <Setter Property="Height" Value="22"/>
                </Style>
            </DataGrid.RowStyle>

            <DataGrid.Columns>
                <DataGridTextColumn Header="Website" Binding="{Binding Link, Mode=OneWay}" Foreground="Blue"/>
                <DataGridTextColumn Header="Login/Email" Binding="{Binding Login, Mode=OneWay}"/>
                <DataGridTextColumn Header="Password" Binding="{Binding Password, Mode=OneWay}"/>
            </DataGrid.Columns>

        </DataGrid>
    </Grid>
</Window>
"@
$mainWindowReader = (New-Object System.Xml.XmlNodeReader $mainWindowXaml)
$mainWindow = [Windows.Markup.XamlReader]::Load($mainWindowReader)
$mainWindow.Add_KeyDown(
{
	if ($_.Key -eq "F3")
	{
		$searchWindow.Owner = $mainWindow
		$searchWindow.ShowDialog()
	}
})
$grid = $mainWindow.FindName("Grid")
$grid.ItemsSource = $sites

# ---------------------------------------------------------------------------
# ------------------------ Setting up search window. ------------------------
# ---------------------------------------------------------------------------

[xml] $searchWindowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Search" Height="60" Width="300"
        WindowStartupLocation="CenterOwner"
		FocusManager.FocusedElement="{Binding ElementName=SearchBox}"
        Topmost="True"
        ResizeMode="NoResize">
    <Grid>
        <TextBox x:Name="SearchBox" VerticalContentAlignment="Center" />
    </Grid>
</Window>
"@
$searchWindowReader = (New-Object System.Xml.XmlNodeReader $searchWindowXaml)
$searchWindow = [Windows.Markup.XamlReader]::Load($searchWindowReader)
$searchWindow.Add_Closing(
{
	$_.Cancel = $true
	$searchWindow.Hide()
})
$searchWindow.Add_KeyDown(
{
	if ($_.Key -eq "Escape")
	{
		$searchWindow.Hide()
		$searchBox.Clear();
	}
	
	if (($_.Key -eq "F3") -or ($_.Key -eq "Enter"))
	{
		$searchPhrase = $searchBox.Text
		
		$grid.SelectedCells.Clear();
		
		foreach ($item in $grid.Items) 
		{
			[Site] $site = $item
			
			if ($site.Link -like "*$($searchPhrase)*")
			{
				$cell = [System.Windows.Controls.DataGridCellInfo]::new($item, $grid.Columns[0])
				$grid.SelectedCells.Add($cell)
			}
			
			if ($site.Login -like "*$($searchPhrase)*")
			{
				$cell = [System.Windows.Controls.DataGridCellInfo]::new($item, $grid.Columns[1])
				$grid.SelectedCells.Add($cell)
			}
			
			if ($site.Password -like "*$($searchPhrase)*")
			{
				$cell = [System.Windows.Controls.DataGridCellInfo]::new($item, $grid.Columns[2])
				$grid.SelectedCells.Add($cell)
			}
		}
		
		if ($grid.SelectedCells.Count -gt 0)
		{
			$grid.ScrollIntoView($grid.SelectedCells[0].Item);
		}
		
		$searchWindow.Hide()
		$searchBox.Clear();
	}
})
$searchBox = $searchWindow.FindName("SearchBox")

# ---------------------------------------------------------------------------
# -------------------------------- Starting. --------------------------------
# ---------------------------------------------------------------------------

$result = $mainWindow.ShowDialog()

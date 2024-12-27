extends CanvasLayer

func level(num):
	$CurrentLevel.text = "LEVEL: " + str(num)
func coins(num):
	$CoinsLabel.text = str(num)

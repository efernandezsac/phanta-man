extends CanvasLayer

func level(num):
	$CurrentLevel.text = "Level: " +str(num)
func coins(num):
	$CoinsLabel.text = "Coins: " + str(num)

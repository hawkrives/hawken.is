---
date: 2020-07-05 21:30
tags: dolphin, emulator, nintendo
---

# Mario Party

… on Mac, via Dolphin, with two local players and with one multiplayer over the internet, shown on a TV.

So! Let's get started, shall we?

I am using [Dolphin](https://dolphin-emu.org), version `5.0-12247`, on macOS 10.15.4, on a Retina MacBook Pro 2012 with the discrete NVIDIA GeForce GT 650M graphics card.

1. Download Dolphin
2. Get an ISO for the game you want to play, by extracting it from a physical copy of the game that you own
3. Open Dolphin's "Graphics" settings, from the Options menu, and change "Backend" to "Vulkan" (this appears to be a Vulkan-to-Metal translator). I let it use my NVIDIA card, but the integrated Intel card might work as well.
4. I left all of the Enhancements at their default settings
5. New with Dolphin 5.0-12247, you can convert the ISOs into "rvz" files, via "Convert file" in the context menu. (Smaller on disk, they are.)

I connected two controllers to my Mac: a Switch Pro Controller, and an off-brand Switch GameCube controller. To connect these to your Mac, open Bluetooth preferences (and make sure Bluetooth is turned on!), then press and hold the little Connect dot on the controller. Then you can connect it to your Mac!

Once you've got the controllers connected, switch back to Dolphin. Open the Controllers settings, set Port 1 to Standard Controller, and hit Configure.

From the Device menu on the top left, pick the controller that you want to configure. I looked for the keywords "Pro Controller" to find my pro controller, and the other thing that said "Controller" I deemed to be the GameCube controller.

I then mapped each of my buttons, as appropriate, and I calibrated the joysticks.

I don't understand what `L-Analog` and `R-Analog` are, or how they differ from `L` and `R`, but I set L/R to L/R, and L/R-Analog to Z-L/Z-R.

I then "save"d these settings as "Pro Controller", and similarly set up the GameCube controller as "GameCube Controller".

If you want multiple local players, you can select multiple controller port as Standard Controller in the controller settings, and the game will detect them as controllers that are plugged into the console.

Dolphin has a Tools → Netplay option, which I intend to use, but I have not yet tried.
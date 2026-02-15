// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { application } from "./application"

// Import and register controllers
import TripGearController from "./trip_gear_controller"

application.register("trip-gear", TripGearController)

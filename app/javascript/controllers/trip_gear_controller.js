import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["availableItem", "tripItem", "tripList", "totalWeight", "totalItems"]

  connect() {
    console.log("Drag and drop controller connected")
  }

  dragStart(event) {
    const gearId = event.currentTarget.dataset.gearId
    event.dataTransfer.effectAllowed = "copy"
    event.dataTransfer.setData("text/plain", gearId)
    event.currentTarget.classList.add("dragging")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("dragging")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  dragEnter(event) {
    if (event.currentTarget === this.tripListTarget) {
      this.tripListTarget.classList.add("drag-over")
    }
  }

  dragLeave(event) {
    if (event.currentTarget === this.tripListTarget) {
      this.tripListTarget.classList.remove("drag-over")
    }
  }

  drop(event) {
    event.preventDefault()
    this.tripListTarget.classList.remove("drag-over")
    
    const gearId = event.dataTransfer.getData("text/plain")
    this.addGearToTrip(gearId)
  }

  async addGearToTrip(gearId) {
    const tripId = this.element.dataset.tripId
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    try {
      const response = await fetch(`/trips/${tripId}/trip_gears`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          trip_gear: {
            gear_item_id: gearId,
            quantity: 1
          }
        })
      })

      if (response.ok) {
        // Reload the page to show updated gear list
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.error || "Failed to add gear")
      }
    } catch (error) {
      console.error("Error adding gear:", error)
      alert("Failed to add gear to trip")
    }
  }

  async removeGear(event) {
    event.preventDefault()
    
    if (!confirm("Remove this gear from the trip?")) {
      return
    }

    const tripGearId = event.currentTarget.dataset.tripGearId
    const tripId = this.element.dataset.tripId
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    try {
      const response = await fetch(`/trips/${tripId}/trip_gears/${tripGearId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        window.location.reload()
      } else {
        alert("Failed to remove gear")
      }
    } catch (error) {
      console.error("Error removing gear:", error)
      alert("Failed to remove gear from trip")
    }
  }

  async togglePacked(event) {
    const checkbox = event.currentTarget
    const tripGearId = checkbox.dataset.tripGearId
    const tripId = this.element.dataset.tripId
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    try {
      const response = await fetch(`/trips/${tripId}/trip_gears/${tripGearId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          trip_gear: {
            packed: checkbox.checked
          }
        })
      })

      if (!response.ok) {
        checkbox.checked = !checkbox.checked
        alert("Failed to update packed status")
      }
    } catch (error) {
      console.error("Error updating packed status:", error)
      checkbox.checked = !checkbox.checked
    }
  }
}

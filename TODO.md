# Gear List – Backlog / TODO

Improvements planned for the gear list and related features.

---

## 🐛 Bugs

- [x] **Bulk delete fails** – "Maybe you tried to change something you didn't have access to." error when deleting multiple gear items → fixed by adding `data-turbo="false"` to the bulk form



---

## Gear List Views & Filters

- [x] **Table view** – dense, sortable table (name, brand, weight, category, trips used)
- [x] **Card / grid view** – visual card layout, switchable with table view
- [x] **Filter bar** – filter by category, weight range, brand, trips used / not used
- [x] **Sort controls** – sort by name, weight, category, date added
- [x] **Search** – free-text search across name, brand, model, notes
- [x] **"Unused gear" view** – items not assigned to any trip

## Bulk Edit

- [x] **Bulk select** – checkboxes to select multiple items
- [x] **Bulk category assign** – change category for selected items
- [x] **Bulk delete** – delete multiple items at once
- [x] **Bulk export** – download selected items as CSV/XLSX

## Import Improvements

- [ ] **Duplicate detection** – warn / skip items with the same name on import
- [ ] **Update existing** – option to update existing items instead of creating duplicates
- [ ] **Preview before import** – show a summary of what will be created before confirming
- [ ] **Manual header row selection** – let user pick the header row if auto-detection is wrong

## Gear Item Detail

- [ ] **Photo upload** – attach an image to a gear item
- [ ] **Purchase link / URL field**
- [ ] **Condition field** – new / good / worn / retired
- [ ] **Tags** – free-form tags in addition to categories

## Statistics

- [ ] **Category weight breakdown** – pie/bar chart of weight by category
- [ ] **Heaviest items** – quick view of top 10 heaviest items
- [ ] **Weight trend across trips** – how pack weight changes over trips

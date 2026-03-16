Power Apps 3-list starter pack

Import order
1. Lists_ProductFamilies.xlsx
2. Lists_Products_Trimmed.xlsx
3. Lists_ProductMaterialCodes_Trimmed.xlsx

Recommended app structure
1. Start screen = Families
   - Data source: ProductFamilies
   - Main list/gallery field: Title
   - Optional extra field: ProductCount

2. Second screen = Products
   - Data source: Products
   - Filter by selected family:
     Filter(Lists_Products_Trimmed, FamilyKey = GalleryFamilies.Selected.FamilyKey)

3. Third screen = Product detail
   - Data source: Products detail form
   - Add a gallery for material codes:
     Filter(Lists_ProductMaterialCodes_Trimmed, ProductKey = GalleryProducts.Selected.ProductKey)

Notes
- ProductFamilies is the navigation layer
- Products is the main product master
- ProductMaterialCodes owns the material codes
- The old combined MaterialCodes column was intentionally removed from Products to reduce confusion

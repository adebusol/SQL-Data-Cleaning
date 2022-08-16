SELECT * FROM housing_data

-- Standardise the date format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM housing_data

UPDATE housing_data
SET SaleDate = CONVERT(Date, SaleDate)

--Populate Property Address data
SELECT PropertyAddress FROM housing_data
WHERE PropertyAddress IS NULL
--Self join
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) FROM housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM housing_data a
JOIN housing_data b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

--Break the Address into 3 columns (Address, city, state)
--Property Address
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM housing_data

ALTER TABLE housing_data
Add PropertySplitAddress Nvarchar(255)

UPDATE housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE housing_data
Add PropertySplitCity Nvarchar(255)

UPDATE housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) 

ALTER TABLE housing_data
DROP COLUMN PropertySplitzcity

--Owner Address (address, city, state)
SELECT OwnerAddress FROM housing_data
SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3),PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM housing_data

ALTER TABLE housing_data
Add OwnerSplitAddress Nvarchar(255)

UPDATE housing_data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE housing_data
Add OwnerSplitCity Nvarchar(255)

UPDATE housing_data
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE housing_data
Add OwnerSplitState Nvarchar(255)

UPDATE housing_data
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--change Y or N in 'SoldASVacant' to Yes or No
SELECT DISTINCT(SoldAsVacant) FROM housing_data

SELECT SoldAsVacant,
CASE
    WHEN SoldAsVacant ='N' THEN 'No'
    WHEN SoldAsVacant ='Y' THEN 'Yes'
ELSE SoldAsVacant
END AS SoldAsVacant
FROM housing_data

--Update
UPDATE housing_data
SET SoldAsVacant = CASE
    WHEN SoldAsVacant ='N' THEN 'No'
    WHEN SoldAsVacant ='Y' THEN 'Yes'
ELSE SoldAsVacant
END

--Remove Duplicates
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER()OVER(
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate,LegalReference
    ORDER BY UniqueID
) row_num
FROM housing_data
--ORDER BY ParcelID
)
DELETE FROM RowNumCTE 
WHERE row_num > 1
--ORDER BY PropertyAddress

--Remove unused columns
ALTER TABLE housing_data
DROP COLUMN PropertyAddress,OwnerAddress

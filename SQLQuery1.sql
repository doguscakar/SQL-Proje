use Northwind

/*1.Tanım Sorusu:  Northwind veritabanında toplam kaç tablo vardır? Bu tabloların isimlerini listeleyiniz*/

SELECT COUNT(*) AS TableCount 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';


/*2.JOIN Sorusu:  Her sipariş (Orders) için, Şirket adı (CompanyName), 
çalışan adı (Employee Full Name), sipariş tarihi ve 
gönderici şirketin adı (Shipper) ile birlikte bir liste çıkarın.*/

SELECT
o.OrderID,
c.CompanyName AS SirketAdi,
e.FirstName + ' ' + e.LastName AS CalisanAdi,
o.OrderDate,
s.CompanyName AS GondericiSirket
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Shippers s ON o.ShipVia = s.ShipperID;


/*3.Aggregate Fonksiyon:  Tüm siparişlerin toplam tutarını bulun. 
(Order Details tablosundaki Quantity  UnitPrice üzerinden hesaplayınız)*/

SELECT SUM(Quantity * UnitPrice) AS ToplamTutar
FROM [Order Details]; 


/*4.Gruplama:  Hangi ülkeden kaç müşteri vardır?*/ 

SELECT Country, COUNT(*) AS MusteriSayilari
FROM Customers
GROUP BY Country;


/*5.Subquery Kullanımı:  En pahalı ürünün adını ve fiyatını listeleyiniz.*/

SELECT ProductName, UnitPrice
FROM Products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM Products);


/*6.JOIN ve Aggregate:  Çalışan başına düşen sipariş sayısını gösteren bir liste çıkarınız.*/ 

SELECT emp.EmployeeID, emp.FirstName + ' ' + emp.LastName AS CalisanAdi,
COUNT(ord.OrderID) AS SiparisSayisi
FROM Employees emp
JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
GROUP BY emp.EmployeeID, emp.FirstName, emp.LastName;


/*7.Tarih Filtreleme:  1997 yılında verilen siparişleri listeleyin.*/

SELECT *
FROM Orders
WHERE DATEPART(year, OrderDate) = 1997;


/*8.CASE Kullanımı:  Ürünleri fiyat aralıklarına göre kategorilere ayırarak listeleyin: 020 → Ucuz, 2050 → Orta, 50+ → Pahalı.*/

 SELECT ProductID, ProductName, UnitPrice,
 CASE 
 WHEN UnitPrice < 20 THEN 'Ucuz'
 WHEN UnitPrice BETWEEN 20 AND 50 THEN 'Orta'
 ELSE 'Pahalı' END AS FiyatKategorisi
FROM Products;


/*9.Nested Subquery:  En çok sipariş verilen ürünün adını ve sipariş adedini (adet bazında) bulun.*/

SELECT TOP 1 p.ProductName, SUM(od.Quantity) AS ToplamSiparisAdedi
FROM Products p
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY ToplamSiparisAdedi DESC;


/*10.View Oluşturma:  Ürünler ve kategoriler bilgilerini birleştiren bir görünüm (view) oluşturun.*/

CREATE VIEW UrunlerveKategoriler AS
SELECT pro.ProductID, pro.ProductName, pro.UnitPrice,
cat.CategoryID, cat.CategoryName, cat.Description
FROM Products pro
JOIN Categories cat ON pro.CategoryID = cat.CategoryID;

SELECT * FROM UrunlerveKategoriler;


 /*11.Trigger:  Ürün silindiğinde log tablosuna kayıt yapan bir trigger yazınız.*/

 --silinen ürünlerin bilgilerinin saklanacağı log tablosu
CREATE TABLE UrunSilmeLog (LogID INT IDENTITY(1,1) PRIMARY KEY, ProductID INT,
ProductName NVARCHAR(40), UnitPrice MONEY,
SilmeTarihi DATETIME DEFAULT GETDATE());

--log tablosuna kayıt yapacak trıgger;
CREATE TRIGGER UrunSilmeLogTrigger ON Products
AFTER DELETE AS
BEGIN
INSERT INTO UrunSilmeLog (ProductID, ProductName, UnitPrice)
SELECT ProductID, ProductName, UnitPrice
FROM deleted;
END;
-- ürün ekleme, silme ve log tablosu kontrolu;
INSERT INTO Products (ProductName, UnitPrice) VALUES ('Test Ürünü 2', 10.00);         
DELETE FROM Products WHERE ProductName = 'Test Ürünü 2';                        
SELECT * FROM UrunSilmeLog;                                              


/*12.Stored Procedure:  Belirli bir ülkeye ait müşterileri listeleyen bir stored procedure yazınız.*/

CREATE PROCEDURE MusterileriUlkeyeGoreListele
@Ulke NVARCHAR(50)
AS
BEGIN SELECT CustomerID, CompanyName, ContactName, City
FROM Customers
WHERE Country = @Ulke;
END;

--Stored Procedure'ü Çalıştırma
EXEC MusterileriUlkeyeGoreListele @Ulke = 'Germany';
 

 /*13.Left Join Kullanımı:  Tüm ürünlerin tedarikçileriyle (suppliers) birlikte listesini yapın. 
 Tedarikçisi olmayan ürünler de listelensin.*/

SELECT pro.ProductID, pro.ProductName, sup.SupplierID, sup.CompanyName AS TedarikciSirketi
FROM Products pro
LEFT JOIN Suppliers sup ON pro.SupplierID = sup.SupplierID;


/*14.Fiyat Ortalamasının Üzerindeki Ürünler:  Fiyatı ortalama fiyatın üzerinde olan ürünleri listeleyin.*/

SELECT ProductID, ProductName, UnitPrice
FROM Products
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);


/*15.En Çok Ürün Satan Çalışan:  Sipariş detaylarına göre en çok ürün satan çalışan kimdir?*/
 
SELECT TOP 1 emp.EmployeeID, emp.FirstName, emp.LastName, 
SUM(orddet.Quantity) AS ToplamUrunSayisi
FROM Employees emp
JOIN Orders ord ON emp.EmployeeID = ord.EmployeeID
JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY emp.EmployeeID, emp.FirstName, emp.LastName
ORDER BY ToplamUrunSayisi DESC;


/*16.Ürün Stoğu Kontrolü:  Stok miktarı 10’un altında olan ürünleri listeleyiniz.*/

SELECT ProductName, UnitsInStock
FROM Products
WHERE UnitsInStock < 10;


/*17.Şirketlere Göre Sipariş Sayısı:  Her müşteri şirketinin yaptığı sipariş sayısını ve toplam harcamasını bulun.*/

SELECT cust.CompanyName, COUNT(ord.OrderID) AS SiparisSayisi,
SUM(orddet.UnitPrice * orddet.Quantity) AS ToplamHarcama
FROM Customers cust
LEFT JOIN Orders ord ON cust.CustomerID = ord.CustomerID
LEFT JOIN [Order Details] orddet ON ord.OrderID = orddet.OrderID
GROUP BY cust.CompanyName;


/*18.En Fazla Müşterisi Olan Ülke:  Hangi ülkede en fazla müşteri var? */
 
SELECT TOP 1 Country FROM Customers 
GROUP BY Country
ORDER BY COUNT(*) DESC;


/*19.Her Siparişteki Ürün Sayısı:  Siparişlerde kaç farklı ürün olduğu bilgisini listeleyin. */

SELECT OrderID, COUNT(ProductID) as UrunSayilar FROM [Order Details]
GROUP BY OrderID;


/*20.Ürün Kategorilerine Göre Ortalama Fiyat:  Her kategoriye göre ortalama ürün fiyatını bulun.*/ 

SELECT cate.CategoryName, AVG(pro.UnitPrice) AS OrtalamaFiyat
FROM Products pro
JOIN Categories cate ON pro.CategoryID = cate.CategoryID
GROUP BY cate.CategoryName;


/*21.Aylık Sipariş Sayısı:  Siparişleri ay ay gruplayarak kaç sipariş olduğunu listeleyin.*/

SELECT DATEPART(month, OrderDate) AS Ay, COUNT(*) AS SiparisSayisi
FROM Orders
GROUP BY DATEPART(month, OrderDate);


/*22.Çalışanların Müşteri Sayısı:  Her çalışanın ilgilendiği müşteri sayısını listeleyin.*/

SELECT EmployeeID, COUNT(DISTINCT CustomerID) AS CustomerCount
FROM Orders
GROUP BY EmployeeID;


/*23.Hiç siparişi olmayan müşterileri listeleyin.*/

SELECT cust.CustomerID, cust.CompanyName
FROM Customers cust
WHERE cust.CustomerID NOT IN (SELECT DISTINCT ord.CustomerID FROM Orders ord);


/*24.Siparişlerin Nakliye(Freight) Maliyeti Analizi:  Nakliye maliyetine göre en pahalı 5 siparişi listeleyin.*/

SELECT TOP (5) OrderID, CustomerID, OrderDate, Freight
FROM Orders
ORDER BY Freight DESC;




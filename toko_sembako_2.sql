-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 19, 2023 at 03:38 AM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `toko_sembako_2`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_new_bar` (IN `nama_bar` VARCHAR(100), IN `satuan` ENUM('kg','L','bungkus','buah'), IN `hrg_beli` INT)   BEGIN
  DECLARE new_kode_bar CHAR(4);
  DECLARE max_kode_bar INT;

  SELECT CONVERT(SUBSTRING(MAX(kode_bar), 2, 3), INT) + 1 INTO max_kode_bar FROM bar;
  IF ISNULL(max_kode_bar) THEN
    SET new_kode_bar = 'C001';
  ELSE
    SET new_kode_bar = CONCAT('C', LPAD(max_kode_bar, 3, '0'));
  END IF;

  INSERT INTO bar (kode_bar, nama_bar, satuan, harga_beli, harga_jual, stok, retur) VALUES (new_kode_bar, nama_bar, satuan, hrg_beli, hrg_beli * 1.3, 0, 0);


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `beli_br_n_retur` (IN `k_supp` CHAR(4), IN `k_bar` CHAR(4), IN `hrg_beli` INT, IN `qty_b` INT)   BEGIN

  DECLARE max_kode_beli INT;
  DECLARE new_kode_beli CHAR(4);
  DECLARE total_cost DECIMAL(10,2); -- Add variable for total cost

  SELECT CONVERT(SUBSTRING(MAX(kode_beli), 2, 3), INT) + 1 INTO max_kode_beli FROM buku_beli;

  IF ISNULL(max_kode_beli) THEN
    SET new_kode_beli = 'S001';
  ELSE
    SET new_kode_beli = CONCAT('S', LPAD(max_kode_beli, 3, '0'));
  END IF;

  SET total_cost = hrg_beli * qty_b; -- Calculate total cost once

  UPDATE bar br
  SET br.harga_beli = hrg_beli, br.harga_jual = hrg_beli * 1.3, br.stok = br.stok + qty_b
  WHERE br.kode_bar = k_bar;

  INSERT INTO buku_beli (kode_beli, tgl_b, k_supp, k_bar, qty_b, total_b, retur)
  VALUES (new_kode_beli, CURRENT_DATE, k_supp, k_bar, qty_b, total_cost, 0);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `beli_br_y_retur` (IN `k_supp` CHAR(4), IN `k_bar` CHAR(4), IN `hrg_beli` INT, IN `qty_b` INT, IN `retur` INT)   BEGIN

  DECLARE max_kode_beli INT;
  DECLARE new_kode_beli CHAR(4);

  SELECT CONVERT(SUBSTRING(MAX(kode_beli), 2, 3), INT) + 1 INTO max_kode_beli FROM buku_beli;

  IF ISNULL(max_kode_beli) THEN
    SET new_kode_beli = 'S001';
  ELSE
    SET new_kode_beli = CONCAT('S', LPAD(max_kode_beli, 3, '0'));
  END IF;

  UPDATE bar br
  SET br.harga_beli = hrg_beli, br.harga_jual = hrg_beli * 1.3, br.retur = br.retur + retur, br.stok = br.stok + (qty_b - retur)
  WHERE br.kode_bar = k_bar;

  INSERT INTO buku_beli (kode_beli, tgl_b, k_supp, k_bar, qty_b, total_b, retur)
  VALUES (new_kode_beli, CURRENT_DATE, k_supp, k_bar, qty_b, hrg_beli * qty_b, retur);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `jual_br_n_htg` (IN `kode_cust` CHAR(4), IN `kode_bar` CHAR(4), IN `qty_jual` INT)   BEGIN

  DECLARE max_kode_jual INT;
  DECLARE new_kode_jual CHAR(4);
  DECLARE harga_jual INT;

  SELECT CONVERT(SUBSTRING(MAX(kode_jual), 2, 3), INT) + 1 INTO max_kode_jual FROM buku_jual;

  SELECT br.harga_jual INTO harga_jual
  FROM bar br
  WHERE br.kode_bar = kode_bar;

  IF ISNULL(max_kode_jual) THEN
    SET new_kode_jual = 'J001';
  ELSE
    SET new_kode_jual = CONCAT('J', LPAD(max_kode_jual, 3, '0'));
  END IF;

  UPDATE bar br
  SET br.stok = br.stok - qty_jual
  WHERE br.kode_bar = kode_bar;
  

  INSERT INTO buku_jual (kode_jual, tgl_j, k_cust, k_bar, qty_j, total_j, hutang)
  VALUES (new_kode_jual, CURRENT_DATE, kode_cust, kode_bar, qty_jual, qty_jual * harga_jual, 0);
  
  

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `jual_br_y_htg` (IN `kode_cust` CHAR(4), IN `kode_bar` CHAR(4), IN `qty_jual` INT, IN `jml_brg_htg` INT)   BEGIN
  DECLARE max_kode_jual INT;
  DECLARE new_kode_jual CHAR(4);
  DECLARE harga_jual INT;

  SELECT CONVERT(SUBSTRING(MAX(kode_jual), 2, 3), SIGNED) + 1 INTO max_kode_jual FROM buku_jual;

  SELECT br.harga_jual INTO harga_jual
  FROM bar br
  WHERE br.kode_bar = kode_bar;

  IF max_kode_jual IS NULL THEN
    SET new_kode_jual = 'J001';
  ELSE
    SET new_kode_jual = CONCAT('J', LPAD(max_kode_jual, 3, '0'));
  END IF;

  UPDATE bar br
  SET br.stok = br.stok - qty_jual
  WHERE br.kode_bar = kode_bar;
  
  UPDATE cust cs
  SET cs.hutang = cs.hutang + jml_brg_htg * harga_jual
  WHERE cs.kode_cust = kode_cust;

  INSERT INTO buku_jual (kode_jual, tgl_j, k_cust, k_bar, qty_j, total_j, hutang)
  VALUES (new_kode_jual, CURRENT_DATE, kode_cust, kode_bar, qty_jual, qty_jual * harga_jual, jml_brg_htg * harga_jual);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rekap_beli_bulanan` (IN `bulan` INT)   BEGIN
SELECT bb.kode_beli, bb.tgl_b, bb.qty_b, bb.total_b, s.nama_supp, b.nama_bar
    FROM buku_beli AS bb
    JOIN supp AS s ON bb.k_supp = s.kode_supp
    JOIN bar AS b ON bb.k_bar = b.kode_bar
    WHERE MONTH(bb.tgl_b) = bulan;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rekap_jual_bulanan` (IN `bulan` INT)   BEGIN
SELECT 
        MONTH(bj.tgl_j) AS Bulan,
        YEAR(bj.tgl_j) AS Tahun,
        b.nama_bar AS Nama_Barang,
        SUM(bj.qty_j) AS Jumlah_Penjualan,
        SUM(bj.total_j) AS Total_Penjualan
    FROM 
        buku_jual AS bj
    JOIN 
        bar AS b ON bj.k_bar = b.kode_bar
    WHERE 
        MONTH(bj.tgl_j) = bulan 
    GROUP BY 
        MONTH(bj.tgl_j), bj.k_bar;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rekap_total` (IN `bulan` INT)   BEGIN
    DECLARE tgl_awal DATE;
    DECLARE tgl_akhir DATE;

    SET tgl_awal = CONCAT(YEAR(CURDATE()), '-', LPAD(bulan, 2, '0'), '-01');
    SET tgl_akhir = LAST_DAY(tgl_awal);

    SELECT
        SUM(CASE WHEN MONTH(bb.tgl_b) = bulan THEN bb.total_b ELSE 0 END) AS total_pembelian,
        SUM(CASE WHEN MONTH(bj.tgl_j) = bulan THEN bj.total_j ELSE 0 END) AS total_penjualan
    FROM
        buku_beli AS bb
    JOIN buku_jual AS bj ON bb.k_bar = bj.k_bar
    WHERE
        MONTH(bb.tgl_b) = bulan OR MONTH(bj.tgl_j) = bulan;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bar`
--

CREATE TABLE `bar` (
  `kode_bar` char(4) NOT NULL CHECK (`kode_bar` regexp '^C[0-9][0-9][0-9]$'),
  `nama_bar` varchar(100) NOT NULL,
  `satuan` enum('kg','L','bungkus','buah') NOT NULL,
  `harga_beli` int(11) NOT NULL,
  `harga_jual` int(11) NOT NULL DEFAULT (`harga_beli` * 1.3),
  `stok` int(11) NOT NULL,
  `retur` int(11) NOT NULL CHECK (`retur` <= 15)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bar`
--

INSERT INTO `bar` (`kode_bar`, `nama_bar`, `satuan`, `harga_beli`, `harga_jual`, `stok`, `retur`) VALUES
('C001', 'Beras Premium', 'kg', 11000, 14300, 75, 0),
('C002', 'Gula Pasir', 'kg', 12000, 15600, 80, 0),
('C003', 'Minyak Goreng', 'L', 14000, 18200, 150, 0),
('C004', 'Mie Instan', 'bungkus', 2300, 2990, 240, 15),
('C005', 'Telur Ayam', 'buah', 2000, 2600, 210, 5),
('C006', 'Tepung Terigu', 'kg', 10000, 13000, 0, 0),
('C007', 'Sirup', 'L', 25000, 32500, 0, 0);

-- --------------------------------------------------------

--
-- Stand-in structure for view `bar_now`
-- (See below for the actual view)
--
CREATE TABLE `bar_now` (
`Kode Barang` char(4)
,`Nama Barang` varchar(100)
,`Satuan` enum('kg','L','bungkus','buah')
,`Harga Beli` int(11)
,`Harga Jual` int(11)
,`Stok` int(11)
,`Retur` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `bar_retur`
-- (See below for the actual view)
--
CREATE TABLE `bar_retur` (
`Kode Barang` char(4)
,`Nama Barang` varchar(100)
,`Stok` int(11)
,`Retur` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `bar_retur_supp`
-- (See below for the actual view)
--
CREATE TABLE `bar_retur_supp` (
`Kode Beli` char(4)
,`Tanggal Beli` date
,`Kode Supplier` char(4)
,`Kode Barang` char(4)
,`Jumlah Retur` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `buku_beli`
--

CREATE TABLE `buku_beli` (
  `kode_beli` char(4) NOT NULL CHECK (`kode_beli` regexp '^S[0-9][0-9][0-9]$'),
  `tgl_b` date NOT NULL,
  `k_supp` char(4) NOT NULL,
  `k_bar` char(4) NOT NULL,
  `qty_b` int(11) NOT NULL,
  `total_b` int(11) NOT NULL,
  `retur` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `buku_beli`
--

INSERT INTO `buku_beli` (`kode_beli`, `tgl_b`, `k_supp`, `k_bar`, `qty_b`, `total_b`, `retur`) VALUES
('S001', '2023-06-01', 'P001', 'C001', 10, 143000, 0),
('S002', '2023-06-02', 'P002', 'C002', 15, 234000, 0),
('S003', '2023-06-03', 'P003', 'C003', 20, 364000, 0),
('S004', '2023-06-04', 'P004', 'C004', 25, 71500, 0),
('S005', '2023-06-05', 'P005', 'C005', 30, 78000, 0),
('S006', '2023-12-18', 'P004', 'C004', 15, 34500, 5),
('S007', '2023-12-18', 'P004', 'C004', 15, 34500, 5),
('S008', '2023-12-18', 'P004', 'C004', 10, 23000, 0),
('S009', '2023-12-18', 'P005', 'C005', 15, 30000, 5);

-- --------------------------------------------------------

--
-- Table structure for table `buku_jual`
--

CREATE TABLE `buku_jual` (
  `kode_jual` char(4) NOT NULL CHECK (`kode_jual` regexp '^J[0-9][0-9][0-9]$'),
  `tgl_j` date NOT NULL,
  `k_cust` char(4) NOT NULL,
  `k_bar` char(4) NOT NULL,
  `qty_j` int(11) NOT NULL,
  `total_j` int(11) NOT NULL,
  `hutang` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `buku_jual`
--

INSERT INTO `buku_jual` (`kode_jual`, `tgl_j`, `k_cust`, `k_bar`, `qty_j`, `total_j`, `hutang`) VALUES
('J001', '2023-06-10', 'K001', 'C001', 5, 71500, 0),
('J002', '2023-06-11', 'K002', 'C002', 10, 156000, 0),
('J003', '2023-06-12', 'K003', 'C003', 8, 145600, 0),
('J004', '2023-06-13', 'K004', 'C004', 20, 57200, 0),
('J005', '2023-06-14', 'K005', 'C005', 50, 130000, 0),
('J006', '2023-12-18', 'K001', 'C001', 5, 71500, 0),
('J007', '2023-12-18', 'K001', 'C001', 10, 143000, 71500);

-- --------------------------------------------------------

--
-- Table structure for table `cust`
--

CREATE TABLE `cust` (
  `kode_cust` char(4) NOT NULL CHECK (`kode_cust` regexp '^K[0-9][0-9][0-9]$'),
  `nama_cust` varchar(100) NOT NULL,
  `tg_reg_cust` date NOT NULL,
  `hutang` int(11) NOT NULL CHECK (`hutang` <= 450000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cust`
--

INSERT INTO `cust` (`kode_cust`, `nama_cust`, `tg_reg_cust`, `hutang`) VALUES
('K001', 'Andi Setiawan', '2023-01-01', 71500),
('K002', 'Rina Kumala', '2023-02-01', 0),
('K003', 'Budi Santoso', '2023-03-01', 0),
('K004', 'Siti Nurhaliza', '2023-04-01', 0),
('K005', 'Dewi Ayu', '2023-05-01', 0);

-- --------------------------------------------------------

--
-- Stand-in structure for view `htg_cust`
-- (See below for the actual view)
--
CREATE TABLE `htg_cust` (
`Kode Kustomer` char(4)
,`Nama Kustomer` varchar(100)
,`Tanggal Registrasi Kustomer` date
,`Hutang` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `supp`
--

CREATE TABLE `supp` (
  `kode_supp` char(4) NOT NULL CHECK (`kode_supp` regexp '^P[0-9][0-9][0-9]$'),
  `nama_supp` varchar(100) NOT NULL,
  `tg_reg_supp` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `supp`
--

INSERT INTO `supp` (`kode_supp`, `nama_supp`, `tg_reg_supp`) VALUES
('P001', 'Supplier Beras', '2023-01-01'),
('P002', 'Supplier Gula', '2023-01-02'),
('P003', 'Supplier Minyak', '2023-01-03'),
('P004', 'Supplier Mie', '2023-01-04'),
('P005', 'Supplier Telur', '2023-01-05');

-- --------------------------------------------------------

--
-- Structure for view `bar_now`
--
DROP TABLE IF EXISTS `bar_now`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bar_now`  AS SELECT `bar`.`kode_bar` AS `Kode Barang`, `bar`.`nama_bar` AS `Nama Barang`, `bar`.`satuan` AS `Satuan`, `bar`.`harga_beli` AS `Harga Beli`, `bar`.`harga_jual` AS `Harga Jual`, `bar`.`stok` AS `Stok`, `bar`.`retur` AS `Retur` FROM `bar` ;

-- --------------------------------------------------------

--
-- Structure for view `bar_retur`
--
DROP TABLE IF EXISTS `bar_retur`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bar_retur`  AS SELECT `bar`.`kode_bar` AS `Kode Barang`, `bar`.`nama_bar` AS `Nama Barang`, `bar`.`stok` AS `Stok`, `bar`.`retur` AS `Retur` FROM `bar` WHERE `bar`.`retur` > 0 ;

-- --------------------------------------------------------

--
-- Structure for view `bar_retur_supp`
--
DROP TABLE IF EXISTS `bar_retur_supp`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bar_retur_supp`  AS SELECT `bb`.`kode_beli` AS `Kode Beli`, `bb`.`tgl_b` AS `Tanggal Beli`, `bb`.`k_supp` AS `Kode Supplier`, `bb`.`k_bar` AS `Kode Barang`, `bb`.`retur` AS `Jumlah Retur` FROM ((`buku_beli` `bb` join `supp` `s` on(`s`.`kode_supp` = `bb`.`k_supp`)) join `bar` `b` on(`b`.`kode_bar` = `bb`.`k_bar`)) WHERE `bb`.`retur` > 0 GROUP BY `bb`.`kode_beli`, `bb`.`k_bar`, `bb`.`k_supp` ORDER BY `bb`.`tgl_b` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `htg_cust`
--
DROP TABLE IF EXISTS `htg_cust`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `htg_cust`  AS SELECT `cust`.`kode_cust` AS `Kode Kustomer`, `cust`.`nama_cust` AS `Nama Kustomer`, `cust`.`tg_reg_cust` AS `Tanggal Registrasi Kustomer`, `cust`.`hutang` AS `Hutang` FROM `cust` WHERE `cust`.`hutang` > 0 ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bar`
--
ALTER TABLE `bar`
  ADD PRIMARY KEY (`kode_bar`);

--
-- Indexes for table `buku_beli`
--
ALTER TABLE `buku_beli`
  ADD PRIMARY KEY (`kode_beli`,`k_bar`),
  ADD KEY `k_supp` (`k_supp`),
  ADD KEY `k_barang` (`k_bar`);

--
-- Indexes for table `buku_jual`
--
ALTER TABLE `buku_jual`
  ADD PRIMARY KEY (`kode_jual`,`k_bar`),
  ADD KEY `k_cust` (`k_cust`),
  ADD KEY `k_barang` (`k_bar`);

--
-- Indexes for table `cust`
--
ALTER TABLE `cust`
  ADD PRIMARY KEY (`kode_cust`);

--
-- Indexes for table `supp`
--
ALTER TABLE `supp`
  ADD PRIMARY KEY (`kode_supp`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `buku_beli`
--
ALTER TABLE `buku_beli`
  ADD CONSTRAINT `buku_beli_ibfk_1` FOREIGN KEY (`k_supp`) REFERENCES `supp` (`kode_supp`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `buku_beli_ibfk_2` FOREIGN KEY (`k_bar`) REFERENCES `bar` (`kode_bar`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `buku_jual`
--
ALTER TABLE `buku_jual`
  ADD CONSTRAINT `buku_jual_ibfk_1` FOREIGN KEY (`k_cust`) REFERENCES `cust` (`kode_cust`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `buku_jual_ibfk_2` FOREIGN KEY (`k_bar`) REFERENCES `bar` (`kode_bar`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

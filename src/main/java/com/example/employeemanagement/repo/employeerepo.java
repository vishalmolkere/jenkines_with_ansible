package com.example.employeemanagement.repo;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.employeemanagement.entity.Employees;

public interface employeerepo extends JpaRepository<Employees, Long> {
    List<Employees> findByNameContainingIgnoreCase(String name);
    List<Employees> findByPhoneno(long phoneno);
}

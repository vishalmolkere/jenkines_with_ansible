package com.example.employeemanagement.service;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.example.employeemanagement.entity.Employees;
import com.example.employeemanagement.repo.employeerepo;

@Repository
public class Employeeservice {

    @Autowired
    employeerepo emprepo;

    public Employees saveEmployee(Employees employee) {
        return emprepo.save(employee);
    }

    public List<Employees> getAllEmployees() {
        return emprepo.findAll();
    }

    public Optional<Employees> getEmployeeById(Long id) {
        return emprepo.findById(id);
    }

    public Employees updateEmployee(Long id, Employees employeeDetails) {
        Optional<Employees> employeeOptional = emprepo.findById(id);
        if (employeeOptional.isPresent()) {
            Employees existingEmployee = employeeOptional.get();
            existingEmployee.setName(employeeDetails.getName());
            existingEmployee.setEmail(employeeDetails.getEmail());
            existingEmployee.setPhoneno(employeeDetails.getPhoneno());
            existingEmployee.setGender(employeeDetails.getGender());
            existingEmployee.setDesignation(employeeDetails.getDesignation());
            existingEmployee.setSalary(employeeDetails.getSalary());
            return emprepo.save(existingEmployee);
        }
        return null;
    }

    public boolean deleteEmployee(Long id) {
        if (emprepo.existsById(id)) {
            emprepo.deleteById(id);
            return true;
        }
        return false;
    }

    public List<Employees> searchEmployeesByName(String name) {
        return emprepo.findByNameContainingIgnoreCase(name);
    }

    public List<Employees> searchEmployeesByPhone(long phoneno) {
        return emprepo.findByPhoneno(phoneno);
    }
}

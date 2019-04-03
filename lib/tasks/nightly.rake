# frozen_string_literal: true

task :nightly => [:merge, :close, :update]

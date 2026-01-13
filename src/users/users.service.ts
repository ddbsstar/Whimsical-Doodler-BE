import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Users } from './entity/users.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(Users)
    private readonly usersRepository: Repository<Users>,
  ) {}

  // 注册新用户
  async registerUser(): Promise<string> {
    const newUser = await this.usersRepository.create({
      password: '123456',
      nickname: 'John Doe',
      email: 'johndoe@gmail.com',
      avatar: 'avatar.png',
      gender: 'male',
      phone: '0123456789',
    });
    await this.usersRepository.save(newUser);
    return 'users registered';
  }
}
